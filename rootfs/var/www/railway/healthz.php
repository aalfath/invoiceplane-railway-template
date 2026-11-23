<?php
// Railway health check (/healthz): 200 when InvoicePlane's database answers and is installed.
header('Content-Type: text/plain');
header('Cache-Control: no-store');
mysqli_report(MYSQLI_REPORT_OFF);
$db = @mysqli_connect(getenv('DB_HOSTNAME'), getenv('DB_USERNAME'), getenv('DB_PASSWORD'), getenv('DB_DATABASE'), (int) (getenv('DB_PORT') ?: 3306));
if (! $db || ! $db->query('SELECT 1 FROM ip_versions LIMIT 1')) {
    http_response_code(503);
    exit("database unavailable\n");
}
$db->close();
echo "ok\n";
