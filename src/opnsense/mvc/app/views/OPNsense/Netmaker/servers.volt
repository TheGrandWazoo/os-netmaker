{#
 # Copyright (c) 2023 KSA Technologies, LLC
 # Copyright (c) 2023 kevin.adams@ksatechnologies <kevin.adams@ksatechnologies.com>
 # All rights reserved.
 #
 # Redistribution and use in source and binary forms, with or without modification,
 # are permitted provided that the following conditions are met:
 #
 # 1. Redistributions of source code must retain the above copyright notice,
 #    this list of conditions and the following disclaimer.
 #
 # 2. Redistributions in binary form must reproduce the above copyright notice,
 #    this list of conditions and the following disclaimer in the documentation
 #    and/or other materials provided with the distribution.
 #
 # THIS SOFTWARE IS PROVIDED ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES,
 # INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 # AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
 # AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
 # OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 # SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 # INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 # CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 # ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 # POSSIBILITY OF SUCH DAMAGE.
 #}

<script>
    showIntro='1';
    $(document).ready(function() {
        var gridParams = {
            search:'/api/netmaker/settings/searchServers',
            get:'/api/netmaker/settings/getServer/',
            set:'/api/netmaker/settings/setServer/',
            add:'/api/netmaker/settings/addServer/',
            del:'/api/netmaker/settings/delServer/',
            toggle:'/api/netmaker/settings/toggleServer/',
        }

        var gridopt = {
            ajax: true,
            selection: true,
            multiSelect: true,
            rowCount:[10,25,50,100,500,1000],
            url: '/api/netmaker/settings/searchServers',
            formatters: {
                "commands": function (column, row) {
                    return "<button type=\"button\" title=\"{{ lang._('Edit server') }}\" class=\"btn btn-xs btn-default command-edit bootgrid-tooltip\" data-row-id=\"" + row.uuid + "\"><span class=\"fa fa-pencil\"></span></button> " +
                        "<button type=\"button\" title=\"{{ lang._('Copy server') }}\" class=\"btn btn-xs btn-default command-copy bootgrid-tooltip\" data-row-id=\"" + row.uuid + "\"><span class=\"fa fa-clone\"></span></button>" +
                        "<button type=\"button\" title=\"{{ lang._('Remove server') }}\" class=\"btn btn-xs btn-default command-delete bootgrid-tooltip\" data-row-id=\"" + row.uuid + "\"><span class=\"fa fa-trash-o\"></span></button>";
                },
                "rowtoggle": function (column, row) {
                    if (parseInt(row[column.id], 2) == 1) {
                        return "<span style=\"cursor: pointer;\" class=\"fa fa-check-square-o command-toggle\" data-value=\"1\" data-row-id=\"" + row.uuid + "\"></span>";
                    } else {
                        return "<span style=\"cursor: pointer;\" class=\"fa fa-square-o command-toggle\" data-value=\"0\" data-row-id=\"" + row.uuid + "\"></span>";
                    }
                },
                "serverstatus": function (column, row) {
                    if (row.statusCode == "" || row.statusCode == undefined) {
                        // fallback to lastUpdate value (unset if server was not registered)
                        if (row.statusLastUpdate == "" || row.statusLastUpdate == undefined) {
                            return "{{ lang._('not registered') }}";
                        } else {
                            return "{{ lang._('OK') }}";
                        }
                    } else if (row.statusCode == "100") {
                        return "{{ lang._('not registered') }}";
                    } else if (row.statusCode == "200") {
                        return "{{ lang._('OK (registered)') }}";
                    } else if (row.statusCode == "250") {
                        return "{{ lang._('deactivated') }}";
                    } else if (row.statusCode == "300") {
                        return "{{ lang._('configuration error') }}";
                    } else if (row.statusCode == "400") {
                        return "{{ lang._('registration failed') }}";
                    } else if (row.statusCode == "500") {
                        return "{{ lang._('internal error') }}";
                    } else {
                        return "{{ lang._('unknown') }}";
                    }
                },
            },
        };

        /**
         * reload bootgrid, return to current selected page
         */
        function std_bootgrid_reload(gridId) {
            var currentpage = $("#"+gridId).bootgrid("getCurrentPage");
            $("#"+gridId).bootgrid("reload");
            // absolutely not perfect, bootgrid.reload doesn't seem to support when().done()
            setTimeout(function(){
                $('#'+gridId+'-footer  a[data-page="'+currentpage+'"]').click();
            }, 400);
        }

        /**
         * copy actions for selected items from opnsense_bootgrid_plugin.js
         */
        var grid_servers = $("#grid-servers").bootgrid(gridopt).on("loaded.rs.jquery.bootgrid", function (e)
        {
            // toggle all rendered tooltips (once for all)
            $('.bootgrid-tooltip').tooltip();

            // scale footer on resize
            $(this).find("tfoot td:first-child").attr('colspan',$(this).find("th").length - 1);
            $(this).find('tr[data-row-id]').each(function(){
                if ($(this).find('[class*="command-toggle"]').first().data("value") == "0") {
                    $(this).addClass("text-muted");
                }
            });

            // edit dialog id to use
            var editDlg = $(this).attr('data-editDialog');
            var gridId = $(this).attr('id');

            // link Add new to child button with data-action = add
            $(this).find("*[data-action=add]").click(function(){
                if ( gridParams['get'] != undefined && gridParams['add'] != undefined) {
                    var urlMap = {};
                    urlMap['frm_' + editDlg] = gridParams['get'];
                    mapDataToFormUI(urlMap).done(function(){
                        // update selectors
                        formatTokenizersUI();
                        $('.selectpicker').selectpicker('refresh');
                        // clear validation errors (if any)
                        clearFormValidation('frm_' + editDlg);
                    });

                    // show dialog for edit
                    $('#'+editDlg).modal({backdrop: 'static', keyboard: false});
                    //
                    $("#btn_"+editDlg+"_save").unbind('click').click(function(){
                        saveFormToEndpoint(url=gridParams['add'],
                            formid='frm_' + editDlg, callback_ok=function(){
                                $("#"+editDlg).modal('hide');
                                $("#"+gridId).bootgrid("reload");
                            }, true);
                    });
                }  else {
                    console.log("[grid] action add missing")
                }
            });

            // link delete selected items action
            $(this).find("*[data-action=deleteSelected]").click(function(){
                if ( gridParams['del'] != undefined) {
                    stdDialogConfirm('{{ lang._('Confirm removal') }}',
                        '{{ lang._('Do you want to remove the selected item?') }}',
                        '{{ lang._('Yes') }}', '{{ lang._('Cancel') }}', function () {
                        var rows =$("#"+gridId).bootgrid('getSelectedRows');
                        if (rows != undefined){
                            var deferreds = [];
                            $.each(rows, function(key,uuid){
                                deferreds.push(ajaxCall(url=gridParams['del'] + uuid, sendData={},null));
                            });
                            // refresh after load
                            $.when.apply(null, deferreds).done(function(){
                                std_bootgrid_reload(gridId);
                            });
                        }
                    });
                } else {
                    console.log("[grid] action del missing")
                }
            });

        });

        /**
         * copy actions for items from opnsense_bootgrid_plugin.js
         */
        grid_servers.on("loaded.rs.jquery.bootgrid", function(){

            // edit dialog id to use
            var editDlg = $(this).attr('data-editDialog');
            var gridId = $(this).attr('id');

            // edit item
            grid_servers.find(".command-edit").on("click", function(e)
            {
                if (editDlg != undefined && gridParams['get'] != undefined) {
                    var uuid = $(this).data("row-id");
                    var urlMap = {};
                    urlMap['frm_' + editDlg] = gridParams['get'] + uuid;
                    mapDataToFormUI(urlMap).done(function () {
                        // update selectors
                        formatTokenizersUI();
                        $('.selectpicker').selectpicker('refresh');
                        // clear validation errors (if any)
                        clearFormValidation('frm_' + editDlg);
                    });

                    // show dialog for pipe edit
                    $('#'+editDlg).modal({backdrop: 'static', keyboard: false});
                    // define save action
                    $("#btn_"+editDlg+"_save").unbind('click').click(function(){
                        if (gridParams['set'] != undefined) {
                            saveFormToEndpoint(url=gridParams['set']+uuid,
                                formid='frm_' + editDlg, callback_ok=function(){
                                    $("#"+editDlg).modal('hide');
                                    std_bootgrid_reload(gridId);
                                }, true);
                        } else {
                            console.log("[grid] action set missing")
                        }
                    });
                } else {
                    console.log("[grid] action get or data-editDialog missing")
                }
            });

            // copy item, save as new
            grid_servers.find(".command-copy").on("click", function(e)
            {
                if (editDlg != undefined && gridParams['get'] != undefined) {
                    var uuid = $(this).data("row-id");
                    var urlMap = {};
                    urlMap['frm_' + editDlg] = gridParams['get'] + uuid;
                    mapDataToFormUI(urlMap).done(function () {
                        // update selectors
                        formatTokenizersUI();
                        $('.selectpicker').selectpicker('refresh');
                        // clear validation errors (if any)
                        clearFormValidation('frm_' + editDlg);
                    });

                    // show dialog for pipe edit
                    $('#'+editDlg).modal({backdrop: 'static', keyboard: false});
                    // define save action
                    $("#btn_"+editDlg+"_save").unbind('click').click(function(){
                        if (gridParams['add'] != undefined) {
                            saveFormToEndpoint(url=gridParams['add'],
                                formid='frm_' + editDlg, callback_ok=function(){
                                    $("#"+editDlg).modal('hide');
                                    std_bootgrid_reload(gridId);
                                }, true);
                        } else {
                            console.log("[grid] action add missing")
                        }
                    });
                } else {
                    console.log("[grid] action get or data-editDialog missing")
                }
            });

            // delete item
            grid_servers.find(".command-delete").on("click", function(e)
            {
                if (gridParams['del'] != undefined) {
                    var uuid=$(this).data("row-id");
                    stdDialogConfirm('{{ lang._('Confirm removal') }}',
                        '{{ lang._('Do you want to remove the selected item?') }}',
                        '{{ lang._('Yes') }}', '{{ lang._('Cancel') }}', function () {
                        ajaxCall(url=gridParams['del'] + uuid,
                            sendData={},callback=function(data,status){
                                // reload grid after delete
                                $("#"+gridId).bootgrid("reload");
                            });
                    });
                } else {
                    console.log("[grid] action del missing")
                }
            });

            // toggle item
            grid_servers.find(".command-toggle").on("click", function(e)
            {
                if (gridParams['toggle'] != undefined) {
                    var uuid=$(this).data("row-id");
                    $(this).addClass("fa-spinner fa-pulse");
                    ajaxCall(url=gridParams['toggle'] + uuid,
                        sendData={},callback=function(data,status){
                            // reload grid after toggle
                            std_bootgrid_reload(gridId);
                        });
                } else {
                    console.log("[grid] action toggle missing")
                }
            });

            // register server
            grid_servers.find(".command-register").on("click", function(e)
            {
                if (gridParams['register'] != undefined) {
                    var uuid=$(this).data("row-id");
                    stdDialogConfirm('{{ lang._('Confirmation Required') }}',
                        '{{ lang._('Register the selected server with the configured ACME CA?') }}',
                        '{{ lang._('Yes') }}', '{{ lang._('Cancel') }}', function() {
                        ajaxCall(url=gridParams['register'] + uuid,sendData={},callback=function(data,status){
                            // reload grid afterwards
                            $("#"+gridId).bootgrid("reload");
                        });
                    });
                } else {
                    console.log("[grid] action register missing")
                }
            });
        });

        // hook into on-show event for dialog to extend layout.
        $('#DialogServer').on('shown.bs.modal', function (e) {
            // hide options that are irrelevant for the selected CA
            $("#server\\.ca").change(function(){
                $(".ca_options").hide();
                $(".ca_options_"+$(this).val()).show();
            });
            $("#server\\.ca").change();
        })
    });
</script>


<ul class="nav nav-tabs" role="tablist" id="maintabs">
    {% if showIntro|default('0')=='1' %}
    <li class="active"><a data-toggle="tab" id="servers-introduction" href="#subtab_servers-introduction"><b>{{ lang._('Introduction') }}</b></a></li>
    {% endif %}
    <li {% if showIntro|default('0')=='0' %}class="active"{% endif %}><a data-toggle="tab" id="servers-tab" href="#subtab_servers"><b>{{ lang._('Servers') }}</b></a></li>
</ul>

<div class="content-box tab-content">
    {% if showIntro|default('0')=='1' %}
    <div id="subtab_servers-introduction" class="tab-pane fade in active">
        <div class="col-md-12">
            <h1>{{ lang._('Introduction') }}</h1>
            <p>{{ lang._('This plugin supports 3 databases:') }}</p>
            <ul>
              <li>{{ lang._('sqlite - A small, fast, self-contained, and local SQL database engine (default)') }}</li>
              <li>{{ lang._('rqlite - A lightweight and easy-to-use distrubuted relational database based on SQLite.') }}</li>
              <li>{{ lang._('PostgreSQL - An extended SQL open source object-relational database.') }}</li>
            </ul>
        </div>
    </div>
    {% endif %}

    <!-- tab page "Servers" Start -->
    <div id="subtab_servers" class="tab-pane fade {% if showIntro|default('0')=='0' %}in active{% endif %}">
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
    <!-- tab page "Servers" End -->
</div>
{# Include dialogs #}
{{ partial("layout_partials/base_dialog",['fields':formDialogServer,'id':'DialogServer','label':lang._('Edit Server')])}}

 