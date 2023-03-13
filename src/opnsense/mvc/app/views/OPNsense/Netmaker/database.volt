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
        function sqlite_db(parent_row) {
            $parent_row.addClass("hidden");
            $('[id*="netmaker.database.name"]').val("sqlite-local");
            $('[id*="netmaker.database.description"]').val("Default datbase");
        }
        function external_db(parent_row) {
            $parent_row.removeClass("hidden");
            $('[id*="netmaker.database.name"]').val("");
            $('[id*="netmaker.database.description"]').val("");
        }
        function databasetype_toggle() {
            $parent_row = $('.databasetype_child').closest('tr');
            $parent_row.find('div:first').css('padding-left', '20px');
            $('.databasetype_parent').val() === 'sqlite' ? sqlite_db($parent_row) : external_db($parent_row);
        }

        var data_get_map = {'frm_database_settings':"/api/netmaker/settings/get"};

        mapDataToFormUI(data_get_map).done(function(data ){
            formatTokenizersUI();
            $('.selectpicker').selectpicker('refresh');
            databasetype_toggle();
        });

        $("#reconfigureAct").SimpleActionButton({
            onPreAction: function() {
                const dfObj = new $.Deferred();
                saveFormToEndpoint("/api/netmaker/settings/set", 'frm_database_settings', function() {
                    dfObj.resolve();
                });
                return dfObj;
            }
        });

        $('.databasetype_parent').click(function() {
            databasetype_toggle();
        });

        updateServiceControlUI('netmaker');

    });
</script>


<ul class="nav nav-tabs" role="tablist" id="maintabs">
    {% if showIntro|default('0')=='1' %}
    <li class="active"><a data-toggle="tab" id="database-introduction" href="#subtab_database-introduction"><b>{{ lang._('Introduction') }}</b></a></li>
    {% endif %}
    <li {% if showIntro|default('0')=='0' %}class="active"{% endif %}><a data-toggle="tab" id="database-tab" href="#subtab_database"><b>{{ lang._('Database') }}</b></a></li>
</ul>

<div class="content-box tab-content">
    {% if showIntro|default('0')=='1' %}
    <div id="subtab_database-introduction" class="tab-pane fade in active">
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

    <div id="subtab_database" class="tab-pane fade {% if showIntro|default('0')=='0' %}in active{% endif %}">
{{ partial("layout_partials/base_form",['fields':databaseForm,'id':'frm_database_settings','label':lang._('Edit Database')])}}
        <div class="col-md-12">
            <hr />
            <button class="btn btn-primary" id="reconfigureAct"
                data-endpoint='/api/netmaker/service/database'
                data-label="{{ lang._('Apply') }}"
                data-error-title="{{ lang._('Error updating database') }}"
                type="button">
            </button>
            <br />
            <br />
        </div>
    </div>
</div>
