<?php
header('Content-Type: application/json');
header('X-Content-Type-Options: nosniff');

$servername = "mydb.itap.purdue.edu";
$username   = "g1154090";
$password   = "Bowling101";
$database   = "g1154090";

$conn = new mysqli($servername, $username, $password, $database);

if ($conn->connect_error) {
    echo json_encode(array(
        "success" => false,
        "message" => "Connection failed"
    ));
    exit;
}

$conn->set_charset("utf8");

function get_count($conn, $sql) {
    $result = $conn->query($sql);

    if (!$result) {
        http_response_code(500);
        echo json_encode([
            "error" => "SQL query failed",
            "details" => $conn->error
        ]);
        exit;
    }

    $row = $result->fetch_assoc();
    return (int)$row["count_value"];
}

$lots_storage = get_count($conn, "
    SELECT COUNT(*) AS count_value
    FROM StoredIn
    WHERE EndTime IS NULL
");

$open_alerts = get_count($conn, "
    SELECT COUNT(DISTINCT WarehouseID, ZoneCode) AS count_value
    FROM ZoneTempBreach
    WHERE ResolutionStatus = 'Open'
");

$departing_today = get_count($conn, "
    SELECT COUNT(*) AS count_value
    FROM Shipment
    WHERE DATE(DepartureTime) = CURDATE()
");

$arriving_today = get_count($conn, "
    SELECT COUNT(*) AS count_value
    FROM Shipment
    WHERE DATE(ArrivalTime) = CURDATE()
      AND DestinationType = 'Warehouse'
");

$expiring_30 = get_count($conn, "
    SELECT COUNT(*) AS count_value
    FROM StoredIn si
    INNER JOIN Batch b
        ON si.VendorID = b.VendorID
       AND si.BatchNumber = b.BatchNumber
    WHERE si.EndTime IS NULL
      AND b.ExpiryDate BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 30 DAY)
");

echo json_encode([
    "lots_storage" => $lots_storage,
    "open_alerts" => $open_alerts,
    "departing_today" => $departing_today,
    "arriving_today" => $arriving_today,
    "expiring_30" => $expiring_30
]);

$conn->close();
?>