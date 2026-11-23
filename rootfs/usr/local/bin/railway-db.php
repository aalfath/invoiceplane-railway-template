<?php
// Railway helper for InvoicePlane: waits for MariaDB, then, holding a database lock so two
// overlapping deploys never run it at once, installs or migrates the schema and creates the
// first admin from DEFAULT_ADMIN_EMAIL / DEFAULT_ADMIN_PASSWORD (only while no user exists).
declare(strict_types=1);
mysqli_report(MYSQLI_REPORT_OFF);

function out(string $m): void { fwrite(STDOUT, "=> [railway] $m\n"); }

$host = getenv('DB_HOSTNAME'); $port = (int) (getenv('DB_PORT') ?: 3306);
$user = getenv('DB_USERNAME'); $pass = getenv('DB_PASSWORD'); $name = getenv('DB_DATABASE');

$db = null;
for ($i = 1; $i <= 90; $i++) {
    $db = @mysqli_connect($host, $user, $pass, $name, $port);
    if ($db) { break; }
    out("waiting for MariaDB at $host:$port ($i)");
    sleep(2);
}
if (! $db) { out('ERROR: MariaDB did not answer in 3 minutes'); exit(1); }

$r = $db->query("SELECT GET_LOCK('invoiceplane_railway_setup', 600)")->fetch_row();
if ((int) $r[0] !== 1) { out('ERROR: could not get the setup lock'); exit(1); }

if (getenv('DEFAULT_ADMIN_PASSWORD') === false || getenv('DEFAULT_ADMIN_PASSWORD') === '') {
    $t = $db->query("SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = 'ip_users'")->fetch_row();
    $users = 0;
    if ((int) $t[0] === 1) { $users = (int) $db->query('SELECT COUNT(*) FROM ip_users')->fetch_row()[0]; }
    if ($users === 0) { out('ERROR: DEFAULT_ADMIN_PASSWORD is empty; refusing to create an admin with a random password'); exit(1); }
}

$run = function (string $cmd): int {
    $rc = 0;
    passthru('cd /var/www/html && setpriv --reuid=www-data --regid=www-data --init-groups php index.php ' . $cmd . ' 2>&1', $rc);
    return $rc;
};
out('installing or migrating the database');
if ($run('setup/cli/migrate') !== 0) { out('ERROR: migration failed'); exit(1); }
if ($run('setup/cli/create_default_user') !== 0) { out('ERROR: creating the first admin failed'); exit(1); }

$db->query("SELECT RELEASE_LOCK('invoiceplane_railway_setup')");
$db->close();
