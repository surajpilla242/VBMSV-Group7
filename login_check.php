<?php
header('Content-Type: application/json');

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

if ($_SERVER["REQUEST_METHOD"] !== "POST") {
    echo json_encode(array(
        "success" => false,
        "message" => "Invalid request method"
    ));
    exit;
}

$input_username = isset($_POST["username"]) ? trim($_POST["username"]) : "";
$input_password = isset($_POST["password"]) ? $_POST["password"] : "";

if ($input_username === "" || $input_password === "") {
    echo json_encode(array(
        "success" => false,
        "message" => "Username and password are required"
    ));
    exit;
}

$sql = "SELECT PasswordHash, Role FROM Employee WHERE Username = ?";
$stmt = $conn->prepare($sql);

if (!$stmt) {
    echo json_encode(array(
        "success" => false,
        "message" => "Prepare failed"
    ));
    exit;
}

$stmt->bind_param("s", $input_username);

if (!$stmt->execute()) {
    echo json_encode(array(
        "success" => false,
        "message" => "Execute failed"
    ));
    exit;
}

$stmt->bind_result($stored_hash, $role);

if ($stmt->fetch()) {
    $check_hash = crypt($input_password, $stored_hash);

    if ($check_hash === $stored_hash) {
        echo json_encode(array(
            "success" => true,
            "message" => "Login successful",
            "role" => $role
        ));
    } else {
        echo json_encode(array(
            "success" => false,
            "message" => "Invalid username or password"
        ));
    }
} else {
    echo json_encode(array(
        "success" => false,
        "message" => "Invalid username or password"
    ));
}

$stmt->close();
$conn->close();
exit;
?>