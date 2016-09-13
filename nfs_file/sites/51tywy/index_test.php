<?php
$servername = "mysql.default";//docker服务
//$servername = "10.254.54.99";
//$servername = "10.254.116.222";//pods暴露给service的虚拟ip地址或service中定义的名字
$username = "root";
$password = "";

// Create connection
$conn = new mysqli($servername, $username, $password);

// Check connection
if ($conn->connect_error) {
    die("连接错误: " . $conn->connect_error);
}
echo "<h1>成功连接 MySQL 服务器</h1>";

phpinfo();

?>
