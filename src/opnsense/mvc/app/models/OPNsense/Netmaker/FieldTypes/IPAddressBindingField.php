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
namespace OPNsense\Netmaker\FieldTypes;

use OPNsense\Base\FieldTypes\BaseField;
use OPNsense\Base\Validators\CallbackValidator;
use Phalcon\Validation\Validator\Regex;
use Phalcon\Validation\Validator\ExclusionIn;
use Phalcon\Validation\Validator\InclusionIn;
use Phalcon\Validation\Message;
use OPNsense\Firewall\Util;
use OPNsense\Core\Config;
//use OPNsense\Base\Validators\CsvListValidator;

/**
 * Class InterfaceField field type to select usable interfaces, currently this is kind of a backward compatibility
 * package to glue legacy interfaces into the model.
 * @package OPNsense\Base\FieldTypes
 */
class IPAddressBindingField extends BaseField
{
    /**
     * @var bool marks if this is a data node or a container
     */
    protected $internalIsContainer = false;

    /**
     * @var string default validation message string
     */
    protected $internalValidationMessage = "please specify a valid ip address";

    /**
     * @var array collected options
     */
    private static $internalOptionList = array();

    /**
     * @var array filters to use on the interface list
     */
    private $internalFilters = array();

    /**
     * @var string key to use for option selections, to prevent excessive reloading
     */
    private $internalCacheKey = '*';

    /**
     * @var bool field may contain multiple interfaces at once
     */
    private $internalMultiSelect = false;

    /**
     * @var bool add physical interfaces to selection (collected from lagg, vlan)
     */
    private $internalAddParentDevices = false;

    /**
     * @var bool allow dynamic interfaces
     */
    private $internalAllowDynamic = false;

    /**
     *  collect parents for lagg interfaces
     *  @return array named array containing device and lagg interface
     */
    private function getConfigLaggInterfaces()
    {
        $physicalInterfaces = array();
        $configObj = Config::getInstance()->object();
        if (!empty($configObj->laggs)) {
            foreach ($configObj->laggs->children() as $key => $lagg) {
                if (!empty($lagg->members)) {
                    foreach (explode(',', $lagg->members) as $interface) {
                        if (!isset($physicalInterfaces[$interface])) {
                            $physicalInterfaces[$interface] = array();
                        }
                        $physicalInterfaces[$interface][] = (string)$lagg->laggif;
                    }
                }
            }
        }
        return $physicalInterfaces;
    }

    /**
     *  collect parents for vlan interfaces
     *  @return array named array containing device and vlan interfaces
     */
    private function getConfigVLANInterfaces()
    {
        $physicalInterfaces = array();
        $configObj = Config::getInstance()->object();
        if (!empty($configObj->vlans)) {
            foreach ($configObj->vlans->children() as $key => $vlan) {
                if (!isset($physicalInterfaces[(string)$vlan->if])) {
                    $physicalInterfaces[(string)$vlan->if] = array();
                }
                $physicalInterfaces[(string)$vlan->if][] = (string)$vlan->vlanif;
            }
        }
        return $physicalInterfaces;
    }

    /**
     * generate validation data (list of interfaces and well know ports)
     */
    protected function actionPostLoadingEvent()
    {
        if (!isset(self::$internalOptionList[$this->internalCacheKey])) {
            self::$internalOptionList[$this->internalCacheKey] = array();

            $allInterfaces = array();
            $allInterfacesDevices = array(); // mapping device -> interface handle (lan/wan/optX)
            $configObj = Config::getInstance()->object();
            // Iterate over all interfaces configuration and collect data
            if (isset($configObj->interfaces) && $configObj->interfaces->count() > 0) {
                foreach ($configObj->interfaces->children() as $key => $value) {
                    if (!$this->internalAllowDynamic && !empty($value->internal_dynamic)) {
                        continue;
                    }
                    if (!empty($value->ipaddr)) {
                        $allInterfaces[(string)$value->ipaddr] = $value;
                    }
                    if (!empty($value->if)) {
                        $allInterfacesDevices[(string)$value->if] = $key;
                    }
                }
            }

            /*
             * Iterate through the VIP interfaces
             */
            $configObj = Config::getInstance()->object();
            if (isset($configObj->virtualip) && $configObj->virtualip->count() > 0) {
                foreach ($configObj->virtualip->children() as $key => $value) {
                    $allInterfaces[(string)$value->subnet] = $value;
                }
            }

            if ($this->internalAddParentDevices) {
                // collect parents for lagg/vlan interfaces
                $physicalInterfaces = $this->getConfigLaggInterfaces();
                $physicalInterfaces = array_merge($physicalInterfaces, $this->getConfigVLANInterfaces());

                // add unique devices
                foreach ($physicalInterfaces as $interface => $devices) {
                    // construct interface node
                    $interfaceNode = new \stdClass();
                    $interfaceNode->enable = 0;
                    $interfaceNode->descr = "[{$interface}]";
                    $interfaceNode->if = $interface;
                    foreach ($devices as $device) {
                        if (!empty($allInterfacesDevices[$device])) {
                            $configuredInterface = $allInterfaces[$allInterfacesDevices[$device]];
                            if (!empty($configuredInterface->enable)) {
                                // set device enabled if any member is
                                $interfaceNode->enable = (string)$configuredInterface->enable;
                            }
                        }
                    }
                    // only add unconfigured devices
                    if (empty($allInterfacesDevices[$interface])) {
                        $allInterfaces[$interface] = $interfaceNode;
                    }
                }
            }

            // collect this items options
            foreach ($allInterfaces as $key => $value) {
                // use filters to determine relevance
                $isMatched = true;
                foreach ($this->internalFilters as $filterKey => $filterData) {
                    if (isset($value->$filterKey)) {
                        $fieldData = $value->$filterKey;
                    } else {
                        // not found, might be a boolean.
                        $fieldData = "0";
                    }

                    if (!preg_match($filterData, $fieldData)) {
                        $isMatched = false;
                    }
                }
                if ($isMatched) {
                    if (isset($value->mode)) {
                        self::$internalOptionList[$this->internalCacheKey][$key] =
                        !empty($value->descr) ? "{$value->subnet} ({$value->descr})" : strtoupper($key);
                    } else {
                        self::$internalOptionList[$this->internalCacheKey][$key] =
                        !empty($value->descr) ? "{$value->ipaddr} ({$value->descr})" : strtoupper($key);
                    }
                }
            }
            natcasesort(self::$internalOptionList[$this->internalCacheKey]);
        }
    }

    /**
     * set filters to use (in regex) per field, all tags are combined
     * and cached for the next object using the same filters
     * @param $filters filters to use
     */
    public function setFilters($filters)
    {
        if (is_array($filters)) {
            $this->internalFilters = $filters;
            $this->internalCacheKey = md5(serialize($this->internalFilters));
        }
    }

    /**
     * add parent devices to the selection in case the parent has no configuration
     * @param $value boolean value 0/1
     */
    public function setAddParentDevices($value)
    {
        if (trim(strtoupper($value)) == "Y") {
            $this->internalAddParentDevices = true;
        } else {
            $this->internalAddParentDevices = false;
        }
    }

    /**
     * select if multiple interfaces may be selected at once
     * @param $value boolean value 0/1
     */
    public function setMultiple($value)
    {
        if (trim(strtoupper($value)) == "Y") {
            $this->internalMultiSelect = true;
        } else {
            $this->internalMultiSelect = false;
        }
    }

    /**
     * select if dynamic (hotplug) interfaces maybe selectable
     * @param $value boolean value 0/1
     */
    public function setAllowDynamic($value)
    {
        if (trim(strtoupper($value)) == "Y") {
            $this->internalAllowDynamic = true;
        } else {
            $this->internalAllowDynamic = false;
        }
    }

    /**
     * get valid options, descriptions and selected value
     * @return array
     */
    public function getNodeData()
    {
        $result = array();
        // if interface is not required and single, add empty option
        if (!$this->internalIsRequired && !$this->internalMultiSelect) {
            $result[""] = array("value" => gettext("none"), "selected" => 0);
        }

        // Add the 0.0.0.0 (All) network interfaces option.
        $result["0.0.0.0"] = array("value" => gettext("0.0.0.0 (All)"), "selected" => 0);

        // explode interfaces
        $interfaces = explode(',', $this->internalValue);
        foreach (self::$internalOptionList[$this->internalCacheKey] as $optKey => $optValue) {
            if (in_array($optKey, $interfaces)) {
                $selected = 1;
            } else {
                $selected = 0;
            }
            $result[$optKey] = array("value" => $optValue, "selected" => $selected);
        }
        return $result;
    }

    /**
     * Validate network options
     * @param array $network to validate
     * @return bool|Callback
     * @throws \OPNsense\Base\ModelException
     */
    private function validateNetwork($network)
    {
        $messages = array();
        if (!Util::isAlias($network) && !Util::isIpAddress($network) && !Util::isSubnet($network)) {
                $messages[] = sprintf(
                    gettext('Entry "%s" is not a valid IP address.'),
                    $network
                );
        }
        return $messages;
    }

    /**
     * retrieve field validators for this field type
     * @return array returns validators
     */
    public function getValidators()
    {
        $validators = parent::getValidators();
        if ($this->internalValue != null) {
            $validators[] = new CallbackValidator(["callback" => function ($data) {
                return $this->validateNetwork($data);
            }
            ]);
        }
        return $validators;
    }
}
