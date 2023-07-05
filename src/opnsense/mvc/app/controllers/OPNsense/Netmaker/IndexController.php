<?php
/**
 *    Copyright (C) 2015 Deciso B.V.
 *
 *    All rights reserved.
 *
 *    Redistribution and use in source and binary forms, with or without
 *    modification, are permitted provided that the following conditions are met:
 *
 *    1. Redistributions of source code must retain the above copyright notice,
 *       this list of conditions and the following disclaimer.
 *
 *    2. Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *
 *    THIS SOFTWARE IS PROVIDED ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES,
 *    INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 *    AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
 *    AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
 *    OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 *    SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 *    INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 *    CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 *    ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 *    POSSIBILITY OF SUCH DAMAGE.
 *
 */
namespace OPNsense\Netmaker;

use \OPNsense\Netmaker\Netmaker;

/**
 * Class SettingsController Handles settings related API actions for the Netmaker module
 * @package OPNsense\Netmaker
 */
/**
 * Class IndexController
 * @package OPNsense\HAProxy
 */
class IndexController extends \OPNsense\Base\IndexController
{
    /**
     * haproxy index page
     * @throws \Exception
     */
    public function indexAction()
    {
        // include form definitions
        $this->view->formGeneralSettings = $this->getForm("generalSettings");
        $this->view->formDialogNetwork = $this->getForm("dialogNetwork");
        $this->view->formDialogServer = $this->getForm("dialogServer");
        // set additional view parameters
        $mdlNetmaker = new \OPNsense\Netmaker\Netmaker();
        $this->view->showIntro = (string)$mdlNetmaker->general->showIntro;
        // pick the template to serve
        $this->view->pick('OPNsense/Netmaker/index');
    }
}