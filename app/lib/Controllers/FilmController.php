<?php

namespace Dvd_rental\Controllers;

class FilmController extends BaseController {

    protected function getResourceName() {
        return "film";
    }

    public function view($id, $col_name) {
        $mapper = $this->getMapperInstance();
        $model = $mapper->find($id, 'film_id');
        $data['model'] = $model;
        $this->render('view.php', $data);
    }
}

