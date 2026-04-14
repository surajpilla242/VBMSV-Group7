-- ============================================================
-- KPI_QUERIES.SQL
-- IE 332 A3 KPI queries for the cold-chain project
--
-- Notes:
-- 1) A3 says KPIs must be computed from stored data using SQL and
--    should not be manually entered or permanently stored.
-- 2) Warehouse KPIs work directly with the current schema.
-- 3) Driver KPIs require a shipment -> driver assignment in SQL.
--    Your current schema does not store that relationship, even
--    though the generator creates a Python-only shipment_driver map.
--    So this file includes an OPTIONAL schema patch table first.
-- 4) Replace ? placeholders with prepared-statement parameters
--    in your PHP code.
-- ============================================================

-- ============================================================
-- OPTIONAL SCHEMA PATCH FOR DRIVER KPIs
-- Add this only once if you want driver KPIs fully in SQL.
-- ============================================================

CREATE TABLE IF NOT EXISTS ShipmentDriverAssignment (
    ShipmentID   CHAR(15) NOT NULL PRIMARY KEY,
    EmployeeID   CHAR(9)  NOT NULL,
    AssignedTime DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (ShipmentID)
        REFERENCES Shipment(ShipmentID)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    FOREIGN KEY (EmployeeID)
        REFERENCES Driver(EmployeeID)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
) ENGINE=InnoDB;


-- ============================================================
-- WAREHOUSE OVERVIEW TOP SUMMARY BAR
-- ============================================================

-- TOP-1 Lots in storage
SELECT COUNT(*) AS LotsInStorage
FROM StoredIn
WHERE EndTime IS NULL;

-- TOP-2 Zones with open alerts
SELECT COUNT(DISTINCT CONCAT(WarehouseID, '-', ZoneCode)) AS ZonesWithOpenAlerts
FROM ZoneTempBreach
WHERE ResolutionStatus = 'Open';

-- TOP-3 Departing today
SELECT COUNT(*) AS DepartingToday
FROM Shipment
WHERE DATE(DepartureTime) = CURDATE();

-- TOP-4 Arriving today
SELECT COUNT(*) AS ArrivingToday
FROM Shipment
WHERE ArrivalTime IS NOT NULL
  AND DATE(ArrivalTime) = CURDATE();

-- TOP-5 Lots expiring within 30 days
SELECT COUNT(*) AS ExpiringWithin30Days
FROM StoredIn si
JOIN Batch b
    ON si.VendorID = b.VendorID
   AND si.BatchNumber = b.BatchNumber
WHERE si.EndTime IS NULL
  AND b.ExpiryDate BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 30 DAY);


-- ============================================================
-- W-KPI-1 Zone Utilization Percentage
-- Utilization(z) = sum(volume of lots currently in zone z) / zone capacity * 100
-- ============================================================

SELECT
    sz.WarehouseID,
    sz.ZoneCode,
    sz.Classification,
    sz.MinTemp,
    sz.MaxTemp,
    sz.CapacityVolume,
    COALESCE(SUM(bl.LotVolume), 0) AS InUseVolume,
    ROUND(COALESCE(SUM(bl.LotVolume), 0) * 100.0 / sz.CapacityVolume, 2) AS UtilizationPct
FROM StorageZone sz
LEFT JOIN StoredIn si
    ON sz.WarehouseID = si.WarehouseID
   AND sz.ZoneCode = si.ZoneCode
   AND si.EndTime IS NULL
LEFT JOIN BatchLot bl
    ON si.VendorID = bl.VendorID
   AND si.BatchNumber = bl.BatchNumber
   AND si.LotSeq = bl.LotSeq
GROUP BY
    sz.WarehouseID,
    sz.ZoneCode,
    sz.Classification,
    sz.MinTemp,
    sz.MaxTemp,
    sz.CapacityVolume
ORDER BY sz.WarehouseID, sz.ZoneCode;

-- Same KPI for one warehouse only
SELECT
    sz.WarehouseID,
    sz.ZoneCode,
    sz.Classification,
    sz.MinTemp,
    sz.MaxTemp,
    sz.CapacityVolume,
    COALESCE(SUM(bl.LotVolume), 0) AS InUseVolume,
    ROUND(COALESCE(SUM(bl.LotVolume), 0) * 100.0 / sz.CapacityVolume, 2) AS UtilizationPct
FROM StorageZone sz
LEFT JOIN StoredIn si
    ON sz.WarehouseID = si.WarehouseID
   AND sz.ZoneCode = si.ZoneCode
   AND si.EndTime IS NULL
LEFT JOIN BatchLot bl
    ON si.VendorID = bl.VendorID
   AND si.BatchNumber = bl.BatchNumber
   AND si.LotSeq = bl.LotSeq
WHERE sz.WarehouseID = ?
GROUP BY
    sz.WarehouseID,
    sz.ZoneCode,
    sz.Classification,
    sz.MinTemp,
    sz.MaxTemp,
    sz.CapacityVolume
ORDER BY sz.ZoneCode;


-- ============================================================
-- W-KPI-2 Lots Expiring Within d Days
-- Default d = 30
-- ============================================================

SELECT
    COUNT(*) AS ExpiringLots
FROM StoredIn si
JOIN Batch b
    ON si.VendorID = b.VendorID
   AND si.BatchNumber = b.BatchNumber
WHERE si.EndTime IS NULL
  AND b.ExpiryDate BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 30 DAY);

-- Per warehouse
SELECT
    si.WarehouseID,
    COUNT(*) AS ExpiringLots
FROM StoredIn si
JOIN Batch b
    ON si.VendorID = b.VendorID
   AND si.BatchNumber = b.BatchNumber
WHERE si.EndTime IS NULL
  AND b.ExpiryDate BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 30 DAY)
GROUP BY si.WarehouseID
ORDER BY si.WarehouseID;

-- Detailed lot list for warehouse detail screen
SELECT
    si.WarehouseID,
    si.ZoneCode,
    v.VendorName,
    si.VendorID,
    si.BatchNumber,
    si.LotSeq,
    bl.LotVolume,
    b.ExpiryDate,
    DATEDIFF(b.ExpiryDate, CURDATE()) AS DaysUntilExpiry
FROM StoredIn si
JOIN BatchLot bl
    ON si.VendorID = bl.VendorID
   AND si.BatchNumber = bl.BatchNumber
   AND si.LotSeq = bl.LotSeq
JOIN Batch b
    ON bl.VendorID = b.VendorID
   AND bl.BatchNumber = b.BatchNumber
JOIN Vendor v
    ON b.VendorID = v.VendorID
WHERE si.EndTime IS NULL
  AND si.WarehouseID = ?
  AND si.ZoneCode = ?
ORDER BY b.ExpiryDate ASC, si.BatchNumber, si.LotSeq;


-- ============================================================
-- W-KPI-3 Open Temperature Excursions
-- ============================================================

SELECT COUNT(*) AS OpenExcursions
FROM ZoneTempBreach
WHERE ResolutionStatus = 'Open';

-- Zones with open alerts by warehouse
SELECT
    WarehouseID,
    COUNT(DISTINCT ZoneCode) AS ZonesWithOpenAlerts
FROM ZoneTempBreach
WHERE ResolutionStatus = 'Open'
GROUP BY WarehouseID
ORDER BY WarehouseID;

-- Open alerts by zone
SELECT
    WarehouseID,
    ZoneCode,
    COUNT(*) AS OpenAlertCount
FROM ZoneTempBreach
WHERE ResolutionStatus = 'Open'
GROUP BY WarehouseID, ZoneCode
ORDER BY WarehouseID, ZoneCode;


-- ============================================================
-- W-KPI-4 Average Excursion Resolution Time
-- Rolling 90-day window
-- ============================================================

SELECT
    ROUND(AVG(TIMESTAMPDIFF(MINUTE, StartTime, EndTime)) / 60.0, 2) AS AvgResolutionHours
FROM ZoneTempBreach
WHERE ResolutionStatus = 'Resolved'
  AND StartTime >= DATE_SUB(NOW(), INTERVAL 90 DAY);

-- Per warehouse
SELECT
    WarehouseID,
    ROUND(AVG(TIMESTAMPDIFF(MINUTE, StartTime, EndTime)) / 60.0, 2) AS AvgResolutionHours
FROM ZoneTempBreach
WHERE ResolutionStatus = 'Resolved'
  AND StartTime >= DATE_SUB(NOW(), INTERVAL 90 DAY)
GROUP BY WarehouseID
ORDER BY WarehouseID;


-- ============================================================
-- W-KPI-5 Weekly Shipment Volume
-- ============================================================

-- Weekly outbound volume
SELECT
    YEAR(DepartureTime) AS ShipYear,
    WEEK(DepartureTime, 1) AS ShipWeek,
    SUM(sl.QuantityVolume) AS WeeklyOutboundVolume
FROM Shipment s
JOIN ShipmentLot sl
    ON s.ShipmentID = sl.ShipmentID
GROUP BY YEAR(DepartureTime), WEEK(DepartureTime, 1)
ORDER BY ShipYear, ShipWeek;

-- Weekly inbound volume
SELECT
    YEAR(ArrivalTime) AS ShipYear,
    WEEK(ArrivalTime, 1) AS ShipWeek,
    SUM(sl.QuantityVolume) AS WeeklyInboundVolume
FROM Shipment s
JOIN ShipmentLot sl
    ON s.ShipmentID = sl.ShipmentID
WHERE s.ArrivalTime IS NOT NULL
GROUP BY YEAR(ArrivalTime), WEEK(ArrivalTime, 1)
ORDER BY ShipYear, ShipWeek;

-- Combined inbound/outbound result for a grouped bar chart
SELECT
    YEAR(EventDate) AS ShipYear,
    WEEK(EventDate, 1) AS ShipWeek,
    Direction,
    SUM(Volume) AS TotalVolume
FROM (
    SELECT
        s.DepartureTime AS EventDate,
        'Outbound' AS Direction,
        sl.QuantityVolume AS Volume
    FROM Shipment s
    JOIN ShipmentLot sl
        ON s.ShipmentID = sl.ShipmentID

    UNION ALL

    SELECT
        s.ArrivalTime AS EventDate,
        'Inbound' AS Direction,
        sl.QuantityVolume AS Volume
    FROM Shipment s
    JOIN ShipmentLot sl
        ON s.ShipmentID = sl.ShipmentID
    WHERE s.ArrivalTime IS NOT NULL
) x
GROUP BY YEAR(EventDate), WEEK(EventDate, 1), Direction
ORDER BY ShipYear, ShipWeek, Direction;


-- ============================================================
-- WAREHOUSE TABLE SUPPORTING QUERIES
-- ============================================================

-- Warehouse table summary: lots stored, open alerts, departing today
SELECT
    w.WarehouseID,
    w.WarehouseName,
    w.Type,
    w.Status,
    COALESCE(ls.LotsStored, 0) AS LotsStored,
    COALESCE(oa.OpenAlerts, 0) AS OpenAlerts,
    COALESCE(dt.DepartingToday, 0) AS DepartingToday
FROM Warehouse w
LEFT JOIN (
    SELECT WarehouseID, COUNT(*) AS LotsStored
    FROM StoredIn
    WHERE EndTime IS NULL
    GROUP BY WarehouseID
) ls
    ON w.WarehouseID = ls.WarehouseID
LEFT JOIN (
    SELECT WarehouseID, COUNT(*) AS OpenAlerts
    FROM ZoneTempBreach
    WHERE ResolutionStatus = 'Open'
    GROUP BY WarehouseID
) oa
    ON w.WarehouseID = oa.WarehouseID
LEFT JOIN (
    SELECT OriginWarehouseID AS WarehouseID, COUNT(*) AS DepartingToday
    FROM Shipment
    WHERE DATE(DepartureTime) = CURDATE()
    GROUP BY OriginWarehouseID
) dt
    ON w.WarehouseID = dt.WarehouseID
ORDER BY w.WarehouseID;

-- Warehouse detail screen: zone table with utilization and alert badge
SELECT
    sz.WarehouseID,
    sz.ZoneCode,
    sz.Classification,
    sz.MinTemp,
    sz.MaxTemp,
    sz.CapacityVolume,
    COALESCE(SUM(bl.LotVolume), 0) AS InUseVolume,
    ROUND(COALESCE(SUM(bl.LotVolume), 0) * 100.0 / sz.CapacityVolume, 2) AS UtilizationPct,
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM ZoneTempBreach ztb
            WHERE ztb.WarehouseID = sz.WarehouseID
              AND ztb.ZoneCode = sz.ZoneCode
              AND ztb.ResolutionStatus = 'Open'
        ) THEN 'OPEN'
        ELSE '—'
    END AS AlertStatus
FROM StorageZone sz
LEFT JOIN StoredIn si
    ON sz.WarehouseID = si.WarehouseID
   AND sz.ZoneCode = si.ZoneCode
   AND si.EndTime IS NULL
LEFT JOIN BatchLot bl
    ON si.VendorID = bl.VendorID
   AND si.BatchNumber = bl.BatchNumber
   AND si.LotSeq = bl.LotSeq
WHERE sz.WarehouseID = ?
GROUP BY
    sz.WarehouseID,
    sz.ZoneCode,
    sz.Classification,
    sz.MinTemp,
    sz.MaxTemp,
    sz.CapacityVolume
ORDER BY sz.ZoneCode;

-- Warehouse detail screen: breach history for one zone
SELECT
    WarehouseID,
    ZoneCode,
    StartTime,
    EndTime,
    MaxDeviation,
    ResolutionStatus
FROM ZoneTempBreach
WHERE WarehouseID = ?
  AND ZoneCode = ?
ORDER BY StartTime DESC;

-- Warehouse detail screen: last 7 days of zone sensor readings
SELECT
    ReadingID,
    SensorID,
    ReadingTime,
    Temperature,
    ReadingStatus
FROM SensorReading
WHERE WarehouseID = ?
  AND ZoneCode = ?
  AND ReadingTime >= DATE_SUB(NOW(), INTERVAL 7 DAY)
ORDER BY ReadingTime ASC;


-- ============================================================
-- DRIVER DASHBOARD KPIs
-- These require ShipmentDriverAssignment in SQL.
-- ============================================================

-- D-KPI-1 On-Time Delivery Rate for one driver
-- Approximates expected transit time using historical average
-- for the same route.
WITH route_avg AS (
    SELECT
        OriginWarehouseID,
        DestinationType,
        DestinationWarehouseID,
        DestinationClinicID,
        AVG(TIMESTAMPDIFF(MINUTE, DepartureTime, ArrivalTime)) AS AvgRouteMinutes
    FROM Shipment
    WHERE Status = 'delivered'
      AND ArrivalTime IS NOT NULL
    GROUP BY
        OriginWarehouseID,
        DestinationType,
        DestinationWarehouseID,
        DestinationClinicID
),
driver_delivered AS (
    SELECT
        s.ShipmentID,
        s.DepartureTime,
        s.ArrivalTime,
        ra.AvgRouteMinutes
    FROM Shipment s
    JOIN ShipmentDriverAssignment sda
        ON s.ShipmentID = sda.ShipmentID
    JOIN route_avg ra
        ON s.OriginWarehouseID <=> ra.OriginWarehouseID
       AND s.DestinationType <=> ra.DestinationType
       AND s.DestinationWarehouseID <=> ra.DestinationWarehouseID
       AND s.DestinationClinicID <=> ra.DestinationClinicID
    WHERE sda.EmployeeID = ?
      AND s.Status = 'delivered'
      AND s.ArrivalTime IS NOT NULL
)
SELECT
    COUNT(*) AS DeliveredTrips,
    SUM(CASE
            WHEN TIMESTAMPDIFF(MINUTE, DepartureTime, ArrivalTime) <= AvgRouteMinutes
            THEN 1 ELSE 0
        END) AS OnTimeTrips,
    ROUND(
        100.0 * SUM(CASE
            WHEN TIMESTAMPDIFF(MINUTE, DepartureTime, ArrivalTime) <= AvgRouteMinutes
            THEN 1 ELSE 0
        END) / NULLIF(COUNT(*), 0),
        2
    ) AS OnTimeRatePct
FROM driver_delivered;

-- D-KPI-2 Temperature Excursion Rate for one driver
SELECT
    COUNT(DISTINCT stb.ShipmentID) AS ShipmentsWithExcursions,
    COUNT(DISTINCT s.ShipmentID) AS TotalDriverShipments,
    ROUND(
        100.0 * COUNT(DISTINCT stb.ShipmentID) / NULLIF(COUNT(DISTINCT s.ShipmentID), 0),
        2
    ) AS ExcursionRatePct
FROM Shipment s
JOIN ShipmentDriverAssignment sda
    ON s.ShipmentID = sda.ShipmentID
LEFT JOIN ShipmentTempBreach stb
    ON s.ShipmentID = stb.ShipmentID
WHERE sda.EmployeeID = ?;

-- Driver summary card: open temperature alerts
SELECT
    COUNT(*) AS OpenTemperatureAlerts
FROM ShipmentTempBreach stb
JOIN ShipmentDriverAssignment sda
    ON stb.ShipmentID = sda.ShipmentID
WHERE sda.EmployeeID = ?
  AND stb.ResolutionStatus = 'Open';

-- D-KPI-3 Missing Reading Rate for one driver
SELECT
    SUM(CASE WHEN sr.ReadingStatus = 'Missing' THEN 1 ELSE 0 END) AS MissingReadings,
    COUNT(*) AS TotalReadings,
    ROUND(
        100.0 * SUM(CASE WHEN sr.ReadingStatus = 'Missing' THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0),
        2
    ) AS MissingReadingRatePct
FROM SensorReading sr
JOIN ShipmentDriverAssignment sda
    ON sr.ShipmentID = sda.ShipmentID
WHERE sda.EmployeeID = ?;


-- ============================================================
-- DRIVER SCREEN SUPPORTING QUERIES
-- ============================================================

-- Driver's assigned shipments table
SELECT
    s.ShipmentID,
    s.OriginWarehouseID,
    s.DestinationType,
    s.DestinationWarehouseID,
    s.DestinationClinicID,
    s.VehicleID,
    s.DepartureTime,
    s.ArrivalTime,
    s.Status
FROM Shipment s
JOIN ShipmentDriverAssignment sda
    ON s.ShipmentID = sda.ShipmentID
WHERE sda.EmployeeID = ?
ORDER BY s.DepartureTime DESC;

-- Driver's current vehicle
SELECT
    v.VehicleID,
    v.LicensePlate,
    v.CapacityVolume,
    v.MinTemp,
    v.MaxTemp,
    v.Status
FROM Vehicle v
JOIN Shipment s
    ON v.VehicleID = s.VehicleID
JOIN ShipmentDriverAssignment sda
    ON s.ShipmentID = sda.ShipmentID
WHERE sda.EmployeeID = ?
  AND s.Status IN ('in transit', 'delayed')
ORDER BY s.DepartureTime DESC
LIMIT 1;

-- Sensor panel for a vehicle
SELECT
    SensorID,
    SensorType,
    CalibrationDate,
    Status
FROM Sensor
WHERE VehicleID = ?
ORDER BY SensorID;

-- Last 20 readings for a vehicle
SELECT
    ReadingID,
    SensorID,
    ShipmentID,
    ReadingTime,
    Temperature,
    Latitude,
    Longitude,
    ReadingStatus
FROM SensorReading
WHERE SensorID IN (
    SELECT SensorID
    FROM Sensor
    WHERE VehicleID = ?
)
ORDER BY ReadingTime DESC
LIMIT 20;

-- Shipment details: custody timeline
SELECT
    lce.EventTime,
    lce.EmployeeID,
    CONCAT(e.FirstName, ' ', e.LastName) AS EmployeeName,
    e.Role,
    lce.FromLocation,
    lce.ToLocation,
    lce.FromWarehouseID,
    lce.FromZoneCode,
    lce.FromVehicleID,
    lce.FromClinicID,
    lce.ToWarehouseID,
    lce.ToZoneCode,
    lce.ToVehicleID,
    lce.ToClinicID,
    lce.ConditionConfirmed
FROM LotCustodyEvent lce
JOIN Employee e
    ON lce.EmployeeID = e.EmployeeID
WHERE EXISTS (
    SELECT 1
    FROM ShipmentLot sl
    WHERE sl.ShipmentID = ?
      AND sl.VendorID = lce.VendorID
      AND sl.BatchNumber = lce.BatchNumber
      AND sl.LotSeq = lce.LotSeq
)
ORDER BY lce.EventTime ASC, lce.CustodyEventID ASC;

-- Shipment details: manifest table
SELECT
    v.VendorName,
    sl.VendorID,
    sl.BatchNumber,
    sl.LotSeq,
    sl.QuantityVolume,
    b.ExpiryDate
FROM ShipmentLot sl
JOIN Batch b
    ON sl.VendorID = b.VendorID
   AND sl.BatchNumber = b.BatchNumber
JOIN Vendor v
    ON sl.VendorID = v.VendorID
WHERE sl.ShipmentID = ?
ORDER BY v.VendorName, sl.BatchNumber, sl.LotSeq;

-- Shipment details: temp chart readings
SELECT
    ReadingTime,
    Temperature,
    ReadingStatus
FROM SensorReading
WHERE ShipmentID = ?
ORDER BY ReadingTime ASC;

-- Shipment details: shipment temperature bounds (tightest bounds across lots)
SELECT
    MAX(b.MinTemp) AS RequiredMinTemp,
    MIN(b.MaxTemp) AS RequiredMaxTemp
FROM ShipmentLot sl
JOIN Batch b
    ON sl.VendorID = b.VendorID
   AND sl.BatchNumber = b.BatchNumber
WHERE sl.ShipmentID = ?;

-- Shipment details: shipment breach windows
SELECT
    StartTime,
    EndTime,
    MaxDeviation,
    ResolutionStatus
FROM ShipmentTempBreach
WHERE ShipmentID = ?
ORDER BY StartTime ASC;


-- ============================================================
-- OPTIONAL / BONUS KPIs FROM A3
-- ============================================================

-- OPT-W-1 Zone Breach Frequency Ranking over a date range [t1, t2]
SELECT
    ztb.WarehouseID,
    ztb.ZoneCode,
    sz.Classification,
    COUNT(*) AS BreachCount
FROM ZoneTempBreach ztb
JOIN StorageZone sz
    ON ztb.WarehouseID = sz.WarehouseID
   AND ztb.ZoneCode = sz.ZoneCode
WHERE ztb.StartTime BETWEEN ? AND ?
GROUP BY ztb.WarehouseID, ztb.ZoneCode, sz.Classification
ORDER BY BreachCount DESC, ztb.WarehouseID, ztb.ZoneCode;

-- OPT-D-1 Breach Frequency by Shipment over a date range [t1, t2]
-- Uses the tightest allowed temp range across lots on a shipment.
SELECT
    s.ShipmentID,
    s.DepartureTime,
    SUM(
        CASE
            WHEN sr.Temperature IS NOT NULL
             AND (sr.Temperature < bounds.RequiredMinTemp OR sr.Temperature > bounds.RequiredMaxTemp)
            THEN 1 ELSE 0
        END
    ) AS OutOfRangeReadingCount
FROM Shipment s
JOIN ShipmentDriverAssignment sda
    ON s.ShipmentID = sda.ShipmentID
JOIN SensorReading sr
    ON s.ShipmentID = sr.ShipmentID
JOIN (
    SELECT
        sl.ShipmentID,
        MAX(b.MinTemp) AS RequiredMinTemp,
        MIN(b.MaxTemp) AS RequiredMaxTemp
    FROM ShipmentLot sl
    JOIN Batch b
        ON sl.VendorID = b.VendorID
       AND sl.BatchNumber = b.BatchNumber
    GROUP BY sl.ShipmentID
) bounds
    ON s.ShipmentID = bounds.ShipmentID
WHERE sda.EmployeeID = ?
  AND s.DepartureTime BETWEEN ? AND ?
GROUP BY s.ShipmentID, s.DepartureTime
ORDER BY s.DepartureTime ASC, s.ShipmentID;

-- OPT-D-2 Missing Reading Rate per Trip over a date range [t1, t2]
SELECT
    sr.ShipmentID,
    s.DepartureTime,
    SUM(CASE WHEN sr.ReadingStatus = 'Missing' THEN 1 ELSE 0 END) AS MissingReadings,
    COUNT(*) AS TotalReadings,
    ROUND(
        100.0 * SUM(CASE WHEN sr.ReadingStatus = 'Missing' THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0),
        2
    ) AS MissingRatePct
FROM SensorReading sr
JOIN Shipment s
    ON sr.ShipmentID = s.ShipmentID
JOIN ShipmentDriverAssignment sda
    ON sr.ShipmentID = sda.ShipmentID
WHERE sda.EmployeeID = ?
  AND s.DepartureTime BETWEEN ? AND ?
GROUP BY sr.ShipmentID, s.DepartureTime
ORDER BY s.DepartureTime DESC, sr.ShipmentID;
