<?php

require __DIR__  . '/../../vendor/autoload.php';

$controller = new Dvd_rental\Controllers\ActorController();

if (isset($_GET['id'])) {
  $controller->view($_GET['id'], 'actor_id');
} else {
  $controller->index();
}
