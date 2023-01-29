<?php
/**
 *    Copyright (C) 2018 KSA Technologies, LLC
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

use OPNsense\Base\BaseModel;

class Netmaker extends BaseModel
{
    /**
     * create a new Database
     * @param string $name
     * @param string $description
     * @return string
     */
    public function newDatabase($name, $description = "", $type = "sqlite", $bindaddr = "0.0.0.0")
    {
        $database = $this->databases->database->Add();
        $uuid = $database->getAttributes()['uuid'];
        $database->name = $name;
        $database->description = $description;
        $database->type = $type;
        $database->bindaddr = $bindaddr;
        return $uuid;
    }
    
    /**
     * create a new action
     * @param string $name
     * @param string $description
     * @return string
     */
    public function newNetwork($name, $description = "", $ipv4cidr = "None", $ipv6cidr = "None")
    {
        $network = $this->networks->network->Add();
        $uuid = $network->getAttributes()['uuid'];
        $network->name = $name;
        $network->description = $description;
        $network->ipv4cidr = $ipv4cidr;
        $network->ipv6cidr = $ipv6cidr;
        return $uuid;
    }

    /**
     * create a new action
     * @param string $name
     * @param string $description
     * @return string
     */
    public function newServer($name, $description = "", $basedomain = "None")
    {
        $server = $this->servers->server->Add();
        $uuid = $server->getAttributes()['uuid'];
        $server->name = $name;
        $server->description = $description;
        $server->basedomain = $basedomain;
        return $uuid;
    }
}
