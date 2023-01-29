{#/

Copyright (C) 2018-2019 KSA Technologies, LLC
OPNsense� is Copyright � 2014 � 2015 by Deciso B.V.
All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

1.  Redistributions of source code must retain the above copyright notice,
    this list of conditions and the following disclaimer.

2.  Redistributions in binary form must reproduce the above copyright notice,
    this list of conditions and the following disclaimer in the documentation
    and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED �AS IS� AND ANY EXPRESS OR IMPLIED WARRANTIES,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.

#}

<script>

    $( document ).ready(function() {

        /*
         * get the general settings
         */
        var data_get_map = {'frm_GeneralSettings':"/api/netmaker/settings/get"};

        /*
         * Update service status
         */
        function updateStatus() {
            updateServiceControlUI('netmaker');
        }

        /*
         * Load the general settings data
         */
        function loadGeneralSettings() {
            mapDataToFormUI(data_get_map).done(function() {
                formatTokenizersUI();
                $('.selectpicker').selectpicker('refresh');
            });
        }

        /*
         * save (general) settings and reconfigure
         * @param callback_funct: callback function, receives result status true/false
         */
        function actionReconfigure(callback_function) {
            var result_status = false;
            saveFormToEndpoint("/api/netmaker/settings/set", 'frm_GeneralSettings', function() {
                ajaxCall(url="/api/netmaker/service/reconfigure", sendData={}, callback=function(data,status) {
                    if (status == "success" || data['status'].toLowerCase().trim() == "ok") {
                        result_status = true;
                    }
                    callback_function(result_status);
                });
            });
        }

        /***********************************************************************
         * link grid actions
         **********************************************************************/
        loadGeneralSettings();
        $('a[data-toggle="tab"]').on('shown.bs.tab', function (e) {
            if (e.target.id == 'database-tab') {
                $('#grid-database').bootgrid('destroy'); // always destroy previous grid, so data is always fresh
                $("#grid-database").UIBootgrid({
                    search:'/api/netmaker/settings/searchDatabase',
                    get:'/api/netmaker/settings/getDatabase/',
                    set:'/api/netmaker/settings/setDatabase/',
                    add:'/api/netmaker/settings/addDatabase/',
                    del:'/api/netmaker/settings/delDatabase/',
                    toggle:'/api/netmaker/settings/toggleDatabase/',
                    options: {
                        rowCount:[10,25,50,100,500,1000]
                    }
                });
            } else if (e.target.id == 'servers-tab') {
                $('#grid-servers').bootgrid('destroy'); // always destroy previous grid, so data is always fresh
                $("#grid-servers").UIBootgrid({
                    search:'/api/netmaker/settings/searchServers',
                    get:'/api/netmaker/settings/getServer/',
                    set:'/api/netmaker/settings/setServer/',
                    add:'/api/netmaker/settings/addServer/',
                    del:'/api/netmaker/settings/delServer/',
                    toggle:'/api/netmaker/settings/toggleServer/',
                    options: {
                        rowCount:[10,25,50,100,500,1000]
                    }
                });
            } else if (e.target.id == 'networks-tab') {
                $('#grid-networks').bootgrid('destroy'); // always destroy previous grid, so data is always fresh
                $("#grid-networks").UIBootgrid({
                    search:'/api/netmaker/settings/searchNetworks',
                    get:'/api/netmaker/settings/getNetwork/',
                    set:'/api/netmaker/settings/setNetwork/',
                    add:'/api/netmaker/settings/addNetwork/',
                    del:'/api/netmaker/settings/delNetwork/',
                    toggle:'/api/netmaker/settings/toggleNetwork/',
                    options: {
                        rowCount:[10,25,50,100,500,1000]
                    }
                });
            }
        });

        /***********************************************************************
         * Commands
         **********************************************************************/
        // Reconfigure netmaker - activate changes
        $('[id*="reconfigureAct"]').click(function(){
            // set progress animation
            $('[id*="reconfigureAct_progress"]').addClass("fa fa-spinner fa-pulse");
            actionReconfigure(function(status) {
                // when done, disable progress animation
                $('[id*="reconfigureAct_progress"]').removeClass("fa fa-spinner fa-pulse");
                updateStatus();
                if (!status) {
                    BootstrapDialog.show({
                        type: BootstrapDialog.TYPE_WARNING,
                        title: "{{ lang._('Error reconfiguring netmaker') }}",
                        message: data['status'],
                        draggable: true
                    });
                }
            });
        });

        // Test configuration file
        $('[id*="configtestAct"]').each(function(){
            $(this).click(function(){

            // set progress animation
            $('[id*="configtestAct_progress"]').each(function(){
                $(this).addClass("fa fa-spinner fa-pulse");
            });

            ajaxCall(url="/api/netmaker/service/configtest", sendData={}, callback=function(data,status) {
                // when done, disable progress animation
                $('[id*="configtestAct_progress"]').each(function(){
                    $(this).removeClass("fa fa-spinner fa-pulse");
                });

                if (data['result'].indexOf('ALERT') > -1) {
                    BootstrapDialog.show({
                        type: BootstrapDialog.TYPE_DANGER,
                        title: "{{ lang._('netmaker config contains critical errors') }}",
                        message: data['result'],
                        draggable: true
                    });
                } else if (data['result'].indexOf('WARNING') > -1) {
                    BootstrapDialog.show({
                        type: BootstrapDialog.TYPE_WARNING,
                        title: "{{ lang._('netmaker config contains minor errors') }}",
                        message: data['result'],
                        draggable: true
                    });
                } else {
                    BootstrapDialog.show({
                        type: BootstrapDialog.TYPE_WARNING,
                        title: "{{ lang._('netmaker config test result') }}",
                        message: "{{ lang._('Your netmaker config contains no errors.') }}",
                        draggable: true
                    });
                }
            });
            });
        });

        // form save event handlers for all defined forms
        $('[id*="save_"]').each(function(){
            $(this).click(function(){
                var frm_id = $(this).closest("form").attr("id");
                var frm_title = $(this).closest("form").attr("data-title");

                // set progress animation
                $("#"+frm_id+"_progress").addClass("fa fa-spinner fa-pulse");

                // save data for tab
                saveFormToEndpoint(url="/api/netmaker/settings/set",formid=frm_id,callback_ok=function() {

                    // on correct save, perform reconfigure
                    ajaxCall(url="/api/netmaker/service/reconfigure", sendData={}, callback=function(data,status) {
                        if (status != "success" || data['status'] != 'ok') {
                            BootstrapDialog.show({
                                type: BootstrapDialog.TYPE_WARNING,
                                title: "{{ lang._('Error reconfiguring netmaker') }}",
                                message: data['status'],
                                draggable: true
                            });
                        } else {
                            ajaxCall(url="/api/netmaker/service/status", sendData={}, callback=function(data,status) {
                                updateServiceStatusUI(data['status']);
                            });
                        }
                        // when done, disable progress animation.
                        $("#"+frm_id+"_progress").removeClass("fa fa-spinner fa-pulse");
                    });

                });
            });
        });

        updateStatus();

        // update history on tab state and implement navigation
        if (window.location.hash != "") {
            $('a[href="' + window.location.hash + '"]').click();
        } else {
            $('a[href="#settings"]').click();
        }

        $('.nav-tabs a').on('shown.bs.tab', function (e) {
            history.pushState(null, null, e.target.hash);
        });

    });

</script>

<ul class="nav nav-tabs" role="tablist" id="maintabs">
    {# manually add tabs #}
    {% if showIntro|default('0')=='1' %}
    <li class="active">
        <a data-toggle="tab" href="#introduction">
            <b>{{ lang._('Introduction') }}</b>
        </a>
    </li>
    {% endif %}

    <!-- tab page "Settings" -->
    <li{% if showIntro|default('0')=='1' %} role="presentation" class="dropdown">
        <a data-toggle="dropdown" href="#" class="dropdown-toggle pull-right visible-lg-inline-block visible-md-inline-block visible-xs-inline-block visible-sm-inline-block" role="button">
            <b><span class="caret"></span></b>
        </a>
        <a data-toggle="tab" onclick="$('#settings-introduction').click();" class="visible-lg-inline-block visible-md-inline-block visible-xs-inline-block visible-sm-inline-block" style="border-right:0px;"><b>{{ lang._('Netmaker Settings') }}</b></a>
        <ul class="dropdown-menu" role="menu">
            <li><a data-toggle="tab" id="settings-introduction" href="#subtab_netmaker-settings-introduction">{{ lang._('Introduction') }}</a></li>
            <li><a data-toggle="tab" id="settings-tab" href="#settings">{{ lang._('Settings') }}</a></li>
        </ul>
        {% else %}
         class="active"><a data-toggle="tab" id="settings-tab" href="#settings">{{ lang._('Settings') }}</a>
        {% endif %}
    </li>
    <!-- tab page "Settings" -->

    <!-- tab page "Databases" -->
    <li{% if showIntro|default('0')=='1' %} role="presentation" class="dropdown">
        <a data-toggle="dropdown" href="#" class="dropdown-toggle pull-right visible-lg-inline-block visible-md-inline-block visible-xs-inline-block visible-sm-inline-block" role="button">
            <b><span class="caret"></span></b>
        </a>
        <a data-toggle="tab" onclick="$('#database-introduction').click();" class="visible-lg-inline-block visible-md-inline-block visible-xs-inline-block visible-sm-inline-block" style="border-right:0px;"><b>{{ lang._('Database') }}</b></a>
        <ul class="dropdown-menu" role="menu">
            <li><a data-toggle="tab" id="database-introduction" href="#subtab_netmaker-database-introduction">{{ lang._('Introduction') }}</a></li>
            <li><a data-toggle="tab" id="database-tab" href="#database">{{ lang._('Databases') }}</a></li>
        </ul>
        {% else %}
        ><a data-toggle="tab" id="database-tab" href="#database">{{ lang._('Databases') }}</a>
        {% endif %}
    </li>
    <!-- tab page "Databases" -->

    <!-- tab page "Servers" -->
    <li{% if showIntro|default('0')=='1' %} role="presentation" class="dropdown">
        <a data-toggle="dropdown" href="#" class="dropdown-toggle pull-right visible-lg-inline-block visible-md-inline-block visible-xs-inline-block visible-sm-inline-block" role="button">
            <b><span class="caret"></span></b>
        </a>
        <a data-toggle="tab" onclick="$('#servers-introduction').click();" class="visible-lg-inline-block visible-md-inline-block visible-xs-inline-block visible-sm-inline-block" style="border-right:0px;"><b>{{ lang._('Servers') }}</b></a>
        <ul class="dropdown-menu" role="menu">
            <li><a data-toggle="tab" id="servers-introduction" href="#subtab_netmaker-servers-introduction">{{ lang._('Introduction') }}</a></li>
            <li><a data-toggle="tab" id="servers-tab" href="#servers">{{ lang._('Servers') }}</a></li>
        </ul>
        {% else %}
        ><a data-toggle="tab" id="servers-tab" href="#servers">{{ lang._('Servers') }}</a>
        {% endif %}
    </li>
    <!-- tab page "Servers" -->

    <!-- tab page "Networks" -->
    <li{% if showIntro|default('0')=='1' %} role="presentation" class="dropdown">
        <a data-toggle="dropdown" href="#" class="dropdown-toggle pull-right visible-lg-inline-block visible-md-inline-block visible-xs-inline-block visible-sm-inline-block" role="button">
            <b><span class="caret"></span></b>
        </a>
        <a data-toggle="tab" onclick="$('#networks-introduction').click();" class="visible-lg-inline-block visible-md-inline-block visible-xs-inline-block visible-sm-inline-block" style="border-right:0px;"><b>{{ lang._('Networks') }}</b></a>
        <ul class="dropdown-menu" role="menu">
            <li><a data-toggle="tab" id="networks-introduction" href="#subtab_netmaker-networks-introduction">{{ lang._('Introduction') }}</a></li>
            <li><a data-toggle="tab" id="networks-tab" href="#networks">{{ lang._('Networks') }}</a></li>
        </ul>
        {% else %}
        ><a data-toggle="tab" id="networks-tab" href="#networks">{{ lang._('Networks') }}</a>
        {% endif %}
    </li>
    <!-- tab page "Networks" -->

    {# add automatically generated tabs #}
</ul>

<div class="content-box tab-content">
    <div id="introduction" class="tab-pane fade in{% if showIntro|default('0')=='1' %} active{% endif %}">
        <div class="col-md-12">
            <h1>{{ lang._('Quick Start Guide') }}</h1>
            <p>{{ lang._('Welcome to the Netmaker Server plugin! This plugin is designed to offer features and flexibility of an SBC using the Asterisk framework package.')}}</p>
            <p>{{ lang._('Note that you should configure the SBC plugin in the following order:') }}</p>
            <ul>
              <li>{{ lang._('Add %sDatabase:%s Database connectivity.') | format('<b>', '</b>') }}</li>
              }
            </ul>
            <p>{{ lang._('Please be aware that you need to %smanually%s add the required firewall rules for all configured services.') | format('<b>', '</b>') }}</p>
            <br/>
        </div>
    </div>

    <div id="subtab_netmaker-settings-introduction" class="tab-pane fade">
        <div class="col-md-12">
            <h1>{{ lang._('Settings') }}</h1>
            <p>{{ lang._('The netmaker needs to know what protocol (TCP or UDP) and bind address an endpoint will communicate.') }}</p>
            <ul>
              <li>{{ lang._('%sFQDN or IP:%s The IP address or fully-qualified domain name that should be used when communicating with your server.') | format('<b>', '</b>') }}</li>
              <li>{{ lang._('%sPort:%s The TCP or UDP port that should be used. If unset, the same port the client connected to will be used.') | format('<b>', '</b>') }}</li>
            </ul>
            <br/>
        </div>
    </div>

    <div id="subtab_netmaker-databases-introduction" class="tab-pane fade">
        <div class="col-md-12">
            <h1>{{ lang._('Databases') }}</h1>
            <p>{{ lang._('Netmaker uses a database to keep information for the network. It is defaulted to use SQLite.') }}</p>
            <ul>
              <li>{{ lang._('%sDatabase:%s sqlite.') | format('<b>', '</b>') }}</li>
              <li>{{ lang._('%sPort:%s The TCP or UDP port that should be used. If unset, the same port the client connected to will be used.') | format('<b>', '</b>') }}</li>
            </ul>
            <br/>
        </div>
    </div>
    <div id="settings" class="tab-pane fade in{% if showIntro|default('0')=='0' %} active{% endif %}">
        {{ partial("layout_partials/base_form",['fields':formGeneralSettings,'id':'frm_GeneralSettings'])}}
        <div class="col-md-12">
            <hr/>
            <button class="btn btn-primary" id="reconfigureAct" type="button"><b>{{ lang._('Apply') }}</b> <i id="reconfigureAct_progress" class=""></i></button>
            <br/>
            <br/>
        </div>
    </div>
    <div id="database" class="tab-pane fade">
        <!-- tab page "database" -->
        <table id="grid-database" class="table table-condensed table-hover table-striped table-responsive" data-editDialog="DialogDatabase">
            <thead>
                <tr>
                    <th data-column-id="enabled" data-width="6em" data-type="string" data-formatter="rowtoggle">{{ lang._('Enabled') }}</th>
                    <th data-column-id="name" data-type="string" data-visible="true">{{ lang._('Name') }}</th>
                    <th data-column-id="description" data-type="string">{{ lang._('Description') }}</th>
                    <th data-column-id="type" data-type="string" data-visible="true">{{ lang._('Type') }}</th>
                    <th data-column-id="bindAddress" data-type="string" data-identifier="true" data-visible="true">{{ lang._('IP Address') }}</th>
                    <th data-column-id="bindPort" data-type="string" data-identifier="true" data-visible="true">{{ lang._('Port') }}</th>
                    <th data-column-id="uuid" data-type="string" data-identifier="true" data-visible="false">{{ lang._('ID') }}</th>
                    <th data-column-id="commands" data-width="7em" data-formatter="commands" data-sortable="false">{{ lang._('Commands') }}</th>
                </tr>
            </thead>
            <tbody>
            </tbody>
            <tfoot>
                <tr>
                    <td></td>
                    <td>
                        <button data-action="add" type="button" class="btn btn-xs btn-default"><span class="fa fa-plus"></span></button>
                        <button data-action="deleteSelected" type="button" class="btn btn-xs btn-default"><span class="fa fa-trash-o"></span></button>
                    </td>
                </tr>
            </tfoot>
        </table>
        <!-- apply button "database"-->
        {{ partial("layout_partials/base_dialog",['fields':formDialogDatabase,'id':'DialogDatabase','label':lang._('Edit Database')])}}
        <div class="col-md-12">
            <hr/>
            <button class="btn btn-primary" id="reconfigureAct" type="button">
                <b>{{ lang._('Apply') }}</b>
                <i id="reconfigureAct_progress" class=""></i>
            </button>
            <!-- button class="btn btn-primary" id="configtestAct-database" type="button"><b>{{ lang._('Test syntax') }}</b><i id="configtestAct_progress" class=""></i></button -->
            <br/>
            <br/>
        </div>
    </div>

    <!-- tab page "networks" -->
    <div id="networks" class="tab-pane fade">
        <table id="grid-networks" class="table table-condensed table-hover table-striped table-responsive" data-editDialog="DialogNetwork">
            <thead>
                <tr>
                    <th data-column-id="enabled" data-width="6em" data-type="string" data-formatter="rowtoggle">{{ lang._('Enabled') }}</th>
                    <th data-column-id="name" data-type="string" data-visible="true">{{ lang._('Name') }}</th>
                    <th data-column-id="description" data-type="string">{{ lang._('Description') }}</th>
                    <th data-column-id="ipv4CIDR" data-type="string" data-identifier="true" data-visible="true">{{ lang._('IPv4 CIDR') }}</th>
                    <th data-column-id="ipv6CIDR" data-type="string" data-identifier="true" data-visible="true">{{ lang._('IPv6 CIDR') }}</th>
                    <th data-column-id="uuid" data-type="string" data-identifier="true" data-visible="false">{{ lang._('ID') }}</th>
                    <th data-column-id="commands" data-width="7em" data-formatter="commands" data-sortable="false">{{ lang._('Commands') }}</th>
                </tr>
            </thead>
            <tbody>
            </tbody>
            <tfoot>
                <tr>
                    <td></td>
                    <td>
                        <button data-action="add" type="button" class="btn btn-xs btn-default"><span class="fa fa-plus"></span></button>
                        <button data-action="deleteSelected" type="button" class="btn btn-xs btn-default"><span class="fa fa-trash-o"></span></button>
                    </td>
                </tr>
            </tfoot>
        </table>
        <!--  apply button "networks" -->
        {{ partial("layout_partials/base_dialog",['fields':formDialogNetwork,'id':'DialogNetwork','label':lang._('Edit Network')])}}
        <div class="col-md-12">
            <hr/>
            <button class="btn btn-primary" id="reconfigureAct" type="button">
                <b>{{ lang._('Apply') }}</b>
                <i id="reconfigureAct_progress" class=""></i>
            </button>
            <!-- button class="btn btn-primary" id="configtestAct-networks" type="button"><b>{{ lang._('Test syntax') }}</b><i id="configtestAct_progress" class=""></i></button -->
            <br/>
            <br/>
        </div>
    </div>

    <!-- tab page "servers" -->
    <div id="servers" class="tab-pane fade">
        <table id="grid-servers" class="table table-condensed table-hover table-striped table-responsive" data-editDialog="DialogServer">
            <thead>
                <tr>
                    <th data-column-id="enabled" data-width="6em" data-type="string" data-formatter="rowtoggle">{{ lang._('Enabled') }}</th>
                    <th data-column-id="name" data-type="string" data-visible="true">{{ lang._('Name') }}</th>
                    <th data-column-id="description" data-type="string">{{ lang._('Description') }}</th>
                    <th data-column-id="baseDomain" data-type="string" data-identifier="true" data-visible="true">{{ lang._('Base Domain') }}</th>
                    <th data-column-id="uuid" data-type="string" data-identifier="true" data-visible="false">{{ lang._('ID') }}</th>
                    <th data-column-id="commands" data-width="7em" data-formatter="commands" data-sortable="false">{{ lang._('Commands') }}</th>
                </tr>
            </thead>
            <tbody>
            </tbody>
            <tfoot>
                <tr>
                    <td></td>
                    <td>
                        <button data-action="add" type="button" class="btn btn-xs btn-default"><span class="fa fa-plus"></span></button>
                        <button data-action="deleteSelected" type="button" class="btn btn-xs btn-default"><span class="fa fa-trash-o"></span></button>
                    </td>
                </tr>
            </tfoot>
        </table>
        {{ partial("layout_partials/base_dialog",['fields':formDialogServer,'id':'DialogServer','label':lang._('Edit Server')])}}
        <!--  apply button "servers" -->
        <div class="col-md-12">
            <hr/>
            <button class="btn btn-primary" id="reconfigureAct" type="button">
                <b>{{ lang._('Apply') }}</b>
                <i id="reconfigureAct_progress" class=""></i>
            </button>
            <!-- button class="btn btn-primary" id="configtestAct-servers" type="button"><b>{{ lang._('Test syntax') }}</b><i id="configtestAct_progress" class=""></i></button -->
            <br/>
            <br/>
        </div>
    </div>
</div>
