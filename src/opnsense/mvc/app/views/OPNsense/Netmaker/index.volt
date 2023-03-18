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
</ul>

<div class="content-box tab-content">
    <div id="introduction" class="tab-pane fade in{% if showIntro|default('0')=='1' %} active{% endif %}">
        <div class="col-md-12">
            <h1>{{ lang._('Quick Start Guide') }}</h1>
            <p>{{ lang._('Welcome to the Netmaker Server plugin! This plugin is designed to offer features and flexibility of an SBC using the Asterisk framework package.')}}</p>
            <p>{{ lang._('Note that you should configure the SBC plugin in the following order:') }}</p>
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
    <div id="settings" class="tab-pane fade in{% if showIntro|default('0')=='0' %} active{% endif %}">
        {{ partial("layout_partials/base_form",['fields':formGeneralSettings,'id':'frm_GeneralSettings'])}}
        <div class="col-md-12">
            <hr/>
            <button class="btn btn-primary" id="reconfigureAct" type="button"><b>{{ lang._('Apply') }}</b> <i id="reconfigureAct_progress" class=""></i></button>
            <br/>
            <br/>
        </div>
    </div>
</div>
