<?php
session_start();
header('Content-Type: application/json');

$servername = "mydb.itap.purdue.edu";
$username = "g1154090";
$password = "Bowling101";
$database = "g1154090";

$conn = new mysqli($servername, $username, $password, $database);

if ($conn->connect_error) {
    echo json_encode(array("error" => "Connection failed"));
    exit;
}

$employee_id = isset($_SESSION['employee_id']) ? $_SESSION['employee_id'] : 'EMP-00008';

function get_count($conn, $sql, $employee_id) {
    $stmt = $conn->prepare($sql);

    if (!$stmt) {
        echo json_encode(array("error" => "SQL prepare failed: " . $conn->error));
        exit;
    }

    $stmt->bind_param("s", $employee_id);
    $stmt->execute();
    $count_value = 0;
    $stmt->bind_result($count_value);
    $stmt->fetch();
    $stmt->close();

    return (int)$count_value;
}

/* Shipments this month */
$shipments_this_month = get_count($conn, "
    SELECT COUNT(DISTINCT s.ShipmentID)
    FROM Shipment s
    JOIN LotCustodyEvent lce
        ON s.VehicleID = lce.ToVehicleID
        OR s.VehicleID = lce.FromVehicleID
    WHERE lce.EmployeeID = ?
      AND MONTH(s.DepartureTime) = MONTH(CURDATE())
      AND YEAR(s.DepartureTime) = YEAR(CURDATE())
", $employee_id);

/* Delivered shipments */
$total_delivered = get_count($conn, "
    SELECT COUNT(DISTINCT s.ShipmentID)
    FROM Shipment s
    JOIN LotCustodyEvent lce
        ON s.VehicleID = lce.ToVehicleID
        OR s.VehicleID = lce.FromVehicleID
    WHERE lce.EmployeeID = ?
      AND s.Status = 'delivered'
", $employee_id);

$on_time_rate_pct = ($total_delivered > 0) ? 100 : null;

/* Open temp alerts */
$open_temp_alerts = get_count($conn, "
    SELECT COUNT(*)
    FROM ShipmentTempBreach stb
    JOIN Shipment s
        ON stb.ShipmentID = s.ShipmentID
    JOIN LotCustodyEvent lce
        ON s.VehicleID = lce.ToVehicleID
        OR s.VehicleID = lce.FromVehicleID
    WHERE lce.EmployeeID = ?
      AND stb.ResolutionStatus = 'Open'
", $employee_id);

/* Vehicle status */
$vehicle_status = null;

$sql_vehicle = "
    SELECT v.Status
    FROM Vehicle v
    JOIN LotCustodyEvent lce
        ON v.VehicleID = lce.ToVehicleID
        OR v.VehicleID = lce.FromVehicleID
    WHERE lce.EmployeeID = ?
    ORDER BY lce.EventTime DESC
    LIMIT 1
";

$stmt = $conn->prepare($sql_vehicle);

if (!$stmt) {
    echo json_encode(array("error" => "SQL prepare failed: " . $conn->error));
    exit;
}

$stmt->bind_param("s", $employee_id);
$stmt->execute();
$stmt->bind_result($vehicle_status);
$stmt->fetch();
$stmt->close();

echo json_encode(array(
    "shipments_this_month" => $shipments_this_month,
    "on_time_rate_pct" => $on_time_rate_pct,
    "open_temp_alerts" => $open_temp_alerts,
    "vehicle_status" => $vehicle_status
));

$conn->close();
?>