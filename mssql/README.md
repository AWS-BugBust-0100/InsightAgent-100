# mssql
This agent collects data from mssql and sends it to Insightfinder.
## Installing the Agent

### Before install agent
###### Install freetds for linux/osx
```bash
osx: brew install freetds
linux: yum install freetds
```

### Short Version
```bash
bash <(curl -sS https://raw.githubusercontent.com/insightfinder/InsightAgent/master/utils/fetch-agent.sh) mssql && cd mssql
vi config.ini
sudo ./setup/install.sh --create  # install on localhost
                                  ## or on multiple nodes
sudo ./offline/remote-cp-run.sh list_of_nodes
```

See the `offline` README for instructions on installing prerequisites.

### Long Version
###### Download the agent tarball and untar it:
```bash
curl -fsSLO https://github.com/insightfinder/InsightAgent/raw/master/mssql/mssql.tar.gz
tar xvf mssql.tar.gz && cd mssql
```

###### Set up `config.ini`
```bash
python configure.py
```
See below for a further explanation of each variable. 

#### Automated Install (local or remote)
###### Review propsed changes from install:
```bash
sudo ./setup/install.sh
```

###### Once satisfied, run:
```bash
sudo ./setup/install.sh --create
```

###### To deploy on multiple hosts, instead call 
```bash
sudo ./offline/remote-cp-run.sh list_of_nodes -f <nodelist_file>
```
Where `list_of_nodes` is a list of nodes that are configured in `~/.ssh/config` or otherwise reachable with `scp` and `ssh`.

#### Manual Install (local only)
###### Check Python version & upgrade if using Python 3
```bash
if [[ $(python -V 2>&1 | awk '{ print substr($NF, 1, 1) }') == "3" ]]; then \
2to3 -w getmessages_mssql.py; \
else echo "No upgrade needed"; fi
```

###### Setup pip & required packages:
```bash
sudo ./setup/pip-config.sh
```

###### Test the agent:
```bash
python getmessages_mssql.py -t
```

###### If satisfied with the output, configure the agent to run continuously:
```bash
sudo ./setup/cron-config.sh
```

### Manual Setup Agent on windows 
###### Download the agent tarball and untar it:
```bash
[Download] https://github.com/insightfinder/InsightAgent/raw/master/mssql/mssql.tar.gz
cd mssql
```

###### Install PyInstaller:
```bash
pip install pyinstaller
```

###### create exe file with PyInstaller:
```bash
PyInstaller -D getmessages_mssql.py --add-data=config.ini.template;.\ --add-data=config.ini.template-replay;.\
```

###### Build package:
Create zip package `getmessages_mssql-win.zip` from folder `dist/getmessages_mssql`

### Install Agent on windows
###### Download the agent tarball and untar it:
```bash
[Download] https://github.com/insightfinder/InsightAgent/raw/master/mssql/getmessages_mssql-win.zip
move mssql\getmessages_mssql-win.zip\getmessages_mssql {{AGENT_PATH}}
```
The {{AGENT_PATH}} is new windows path for mssql agent.

###### Set up `config.ini`
```bash
cd {{AGENT_PATH}}
copy config.ini.template config.ini
```
See below for a further explanation of each variable. 

###### Test the agent:
```bash
.\getmessages_mssql.exe -c config.ini -t
```

###### If satisfied with the output, configure the agent to run continuously:
```bash
schtasks /create /tn "InsightAgent Cron Job" /tr "{{AGENT_PATH}}\getmessages_mssql.exe -c {{AGENT_PATH}}\config.ini" /sc hourly
```
Please see [schtasks](https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/schtasks) for more details.

### Config Variables
* **`host`**: Database host. Default value: localhost.
* **`user`**: Database user to connect as. Default value: None.
* **`password`**: User's password. Default value: None.
* **`database`**: The database to initially connect to.
* `timeout`: Query timeout in seconds, default 0 (no timeout).
* `login_timeout`: Timeout for connection and login in seconds, default 60.
* `appname`: Set the application name to use for the connection.
* `port`: The TCP port to use to connect to the server.
* `conn_properties`: SQL queries to send to the server upon connection establishment. Can be a string or another kind of iterable of strings.
* `autocommit`: Whether to use default autocommiting mode or not.
* `tds_version`: TDS protocol version to use.
* **`sql`**: The query string for mssql. Use template filed {{start_time}} or {{end_time}} or {{extract_time}} to replace the time in sql. Example: """SELECT * FROM Table{{extract_time}} WHERE Table{{extract_time}}.Time >= {{start_time}} and Table{{extract_time}}.Time < {{end_time}};"""
* **`sql_time_format`**: The {{start_time}} and {{end_time}} format in sql, as library [arrow](https://arrow.readthedocs.io/en/latest/#supported-tokens). Example: YYYYMMDD
* **`sql_extract_time_offset`**: This options will create template field {{extract_time}}, and with offset of {{end_time}}, unit is second. Example: 86400|-86400|0
* **`sql_extract_time_format`**: The {{extract_time}} format in sql, as library [arrow](https://arrow.readthedocs.io/en/latest/#supported-tokens). Example: YYYYMMDD 
* `sql_time_range`: History data time range, Example: 2020-04-14 00:00:00,2020-04-15 00:00:00. If this option is set, the agent will execute sql by time range and time interval, and `sql_time_interval` is required. 
* `sql_time_interval`: Time range interval, unit is second. Example: 86400.
* `filters_include`: Used to filter messages based on allowed values.
* `filters_exclude`: Used to filter messages based on unallowed values.
* **`data_format`**: The format of the data to parse: RAW, RAWTAIL, CSV, CSVTAIL, XLS, XLSX, JSON, JSONTAIL, AVRO, or XML. \*TAIL formats keep track of the current file being read & the position in the file.
* `raw_regex`: Regex used to parse raw data. Must use named capture groups `(?<name>...)` corresponding to fields defined below, as only those named capture groups will be reported.
* `raw_start_regex`: Regex used to indicate the start of a new multiline message. MUST start with `^` if defined.
* `csv_field_names`: A list of field names for CSV/XLS(X) input. Required, even if the CSV to parse has a header.
* `csv_field_delimiter`: A regex for the field delimiter to use - the default is `,|\t` for commas and tabs.
* `json_top_level`: The top-level of fields to parse in JSON/AVRO/XML. For example, if all fields of interest are nested like 
* **`timestamp_format`**: Format of the timestamp, in python [arrow](https://arrow.readthedocs.io/en/latest/#supported-tokens). If the timestamp is in Unix epoch, this can be set to `epoch`. If the timestamp is split over multiple fields, curlies can be used to indicate formatting, ie: `YYYY-MM-DD HH:mm:ss ZZ`; alternatively, if the timestamp can be in one of multiple fields, a priority list of field names can be given: `timestamp1,timestamp2`.
* `timezone`: Timezone for the data. Note that it cannot be parsed from the timestamp, and will be discarded if only present there.
* `timestamp_field`: Field name for the timestamp. Default is `timestamp`.
* `instance_field`: Field name for the instance name. If not set or the field is not found, the instance name is the hostname of the machine the agent is installed on. This can also use curly formatting or a priority list. Alternatively, if the field is 'complex' - a reference field which holds a link to another API within the same context, a link can be made to that data using the following formatting: `field1!!ref=json|csv|xml|raw&headers={“Accept”:”application/json”}&auth!!field2` where: `field1` is the reference field in this message body; `!!` is a delimiter; `ref=json|csv|xml|raw` indicates that this is a reference link and it returns data in the format of json or csv etc as applicable; `&headers={“Accept”:”application/json”}&auth` indicates which passthrough keywords to pass to requests (either literal, a la `headers={“Accept”:”application/json”}` or using previously-used keywords, a la `auth=auth` when no literal value is given); `!!` is another delimiter; and `field2` is the field in the reference'd data to grab.
* `device_field`: Field name for the device/container for containerized projects. This can also use curly or complex formatting, or a priority list.
* `data_fields`: Comma-delimited list of field names to use as data fields. If not set, all fields will be reported. Each data field can either be a field name (`name`) or a labeled field (`<name>::<value>` or `<name>::==<value>`), where `<name>` and `<value>` can be raw strings (`fieldname::fieldvalue`), curly or complex formatted (`link!!ref=json&auth!!name::=={val} - {ue}`), or a combination. If `::==` is used as the separator, `<value>` is treated as a mathematical expression that can be evaluated with `eval()`.
* `metric_name_field`: If this is set, only the first value in `data_fields` will be used as the field containing the value for the metric who's name is contained here. For example, if `data_fields = count` and `metric_name_field = status`, and the data is `{"count": 20, "status": "success"}`, then the data reported will be `success: 20`.
* `all_metrics`: Agent will send data at once when all metrics in `all_metrics` of instance is collected.
* **`metric_buffer_size_mb`**: Size of buffer (in MB) to fuse metrics. Default is `10`.
* `agent_http_proxy`: HTTP proxy used to connect to the agent.
* `agent_https_proxy`: As above, but HTTPS.
* **`user_name`**: User name in InsightFinder
* **`license_key`**: License Key from your Account Profile in the InsightFinder UI. 
* `token`: Token from your Account Profile in the InsightFinder UI. 
* **`project_name`**: Name of the project created in the InsightFinder UI. 
* **`project_type`**: Type of the project - one of `metric, metricreplay, log, logreplay, incident, incidentreplay, alert, alertreplay, deployment, deploymentreplay`.
* **`sampling_interval`**: How frequently data is collected. Should match the interval used in project settings.
* **`run_interval`**: How frequently the agent is ran. Should match the interval used in cron.
* `chunk_size_kb`: Size of chunks (in KB) to send to InsightFinder. Default is `2048`.
* `if_url`: URL for InsightFinder. Default is `https://app.insightfinder.com`.
* `if_http_proxy`: HTTP proxy used to connect to InsightFinder.
* `if_https_proxy`: As above, but HTTPS.