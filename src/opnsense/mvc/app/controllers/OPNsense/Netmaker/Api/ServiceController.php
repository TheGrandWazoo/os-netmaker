<?php
/**
 *    Copyright (C) 2022 KSA Technologies, LLC
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
namespace OPNsense\Netmaker\Api;

use \OPNsense\Base\ApiMutableServiceControllerBase;
use \OPNsense\Core\Backend;
use \OPNsense\Core\Config;
use \OPNsense\Netmaker\Netmaker;

/**
 * Class ServiceController
 * @package OPNsense\Netmaker
 */
class ServiceController extends ApiMutableServiceControllerBase
{
    protected static $internalServiceClass = '\OPNsense\Netmaker\Netmaker';
    protected static $internalServiceEnabled = 'general.enabled';
    protected static $internalServiceName = 'netmaker';
    protected static $internalServiceTemplate = 'OPNsense/Netmaker';


    public function databaseAction()
    {
        return array('status' => 'Ok');
    }

    public function reconfigureAction()
    {
        $status = "failed";
        if ($this->request->isPost()) {
            $this->sessionClose();
            $mdlNetmaker = new Netmaker;
            $runStatus = $this->statusAction();

            if ($runStatus['status'] == "running" && (string)$mdlNetmaker->general->enabled == 0) {
                $this->stopAction();
            }

            $backend = new Backend();
            $bckresult = trim($backend->configdRun('template reload OPNsense/Netmaker'));
            if ($bckresult == "OK") {
                if ((string)$mdlNetmaker->general->enabled == 1) {
                    if ($runStatus['status'] == 'running') {
                        $status = $this->restartAction()['response'];
                    } else {
                        $status = $this->startAction()['response'];
                    }
                } else {
                    $status = "OK";
                }
            } else {
                $status = "error generating Netmaker template (".$bckresult.")";
            }
        }
        return array("status" => $status);
    }
}
