<?php
/**
 *    Copyright (C) 2016 Frank Wall
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
namespace OPNsense\Netmaker\Api;

use OPNsense\Base\ApiMutableModelControllerBase;
use \OPNsense\Base\UIModelGrid;
use \OPNsense\Core\Config;
use \OPNsense\Netmaker\Netmaker;

/**
 * Class SettingsController
 * @package OPNsense\Netmaker
 */
class SettingsController extends ApiMutableModelControllerBase
{
    protected static $internalModelName = 'netmaker';
    protected static $internalModelClass = '\OPNsense\Netmaker\Netmaker';
    
    // Transport related API's
    public function getDatabaseAction($uuid = null)
    {
        return $this->getBase('database', 'databases.database', $uuid);
    }

    public function setDatabaseAction($uuid)
    {
        return $this->setBase('database', 'databases.database', $uuid);
    }

    public function addDatabaseAction()
    {
        return $this->addBase('database', 'databases.database');
    }

    public function delDatabaseAction($uuid)
    {
        return $this->delBase('databases.database', $uuid);
    }

    public function toggleDatabaseAction($uuid)
    {
        return $this->toggleBase('databases.database', $uuid);
    }

    public function searchDatabasesAction()
    {
        $filter_funct = function ($record) {
            if ($record->bindPort == "") {
                $record->bindPort = "5060 (Default)";
            }
            return true;
        };
        return $this->searchBase('databases.database', array('enabled', 'name', 'description', 'type', 'bindAddress', 'bindPort'), 'name', $filter_funct);
    }

    // Network Related API's
    public function getNetworkAction($uuid = null)
    {
        return $this->getBase('network', 'networks.network', $uuid);
    }

    public function setNetworkAction($uuid)
    {
        return $this->setBase('network', 'networks.network', $uuid);
    }

    public function addNetworkAction()
    {
        return $this->addBase('network', 'networks.network');
    }

    public function delNetworkAction($uuid)
    {
        return $this->delBase('networks.network', $uuid);
    }

    public function toggleNetworkAction($uuid, $enabled = null)
    {
        return $this->toggleBase('networks.network', $uuid);
    }

    public function searchNetworksAction()
    {
        $filter_funct = function ($record) {
            if ($record->ipv4CIDR == "") {
                $record->ipv4CIDR = "None (Default)";
            }
            if ($record->ipv6CIDR == "") {
                $record->ipv6CIDR = "None (Default)";
            }
            return true;
        };
        return $this->searchBase('networks.network', array('enabled', 'name', 'description', 'ipv4CIDR', 'ipv6CIDR'), 'name', $filter_funct);
    }
    
    // Server Related API's
    public function getServerAction($uuid = null)
    {
        return $this->getBase('server', 'servers.server', $uuid);
    }
    
    public function setServerAction($uuid)
    {
        return $this->setBase('server', 'servers.server', $uuid);
    }
    
    public function addServerAction()
    {
        return $this->addBase('server', 'servers.server');
    }
    
    public function delServerAction($uuid)
    {
        return $this->delBase('servers.server', $uuid);
    }
    
    public function toggleServerAction($uuid, $enabled = null)
    {
        return $this->toggleBase('servers.server', $uuid);
    }
    
    public function searchServersAction()
    {
        $filter_funct = function ($record) {
            if ($record->baseDomain == "") {
                $record->baseDomain = "None (Default)";
            }
            return true;
        };
        return $this->searchBase('servers.server', array('enabled', 'name', 'description', 'baseDomain'), 'name', $filter_funct);
    }
}
