## Installation

Install next libraries with embedded gem installer:

    /opt/td-agent/embedded/bin/gem install elasticsearch
    /opt/td-agent/embedded/bin/fluent-gem install fluent-plugin-elasticsearch
    /opt/td-agent/embedded/bin/gem install websocket-eventmachine-client

**Important**: installation of these dependencies will require development tools (gcc, make) and compilation.

Once installed, start fluentd daemon poiting plugins path to directory containing those 3 plugins (either with `-p dir` if you invoke from command line, or with `ENV["FLUENT_PLUGIN"]` if you invoke as service)

## Concept

Changes feed plugin outputs ES events as messages like these:

    {"_index":"sni_cv","_type":"searchdocument","_id":"CRJQ0FF67K490C2PP24Z","_timestamp":"2016-06-07T14:22:55.048Z","_version":2,"_operation":"INDEX","_source":{ <...> }
    {"_index":"sni_cv","_type":"searchdocument","_id":"CRJQ0FG68CQ7L1TXWLJP","_timestamp":"2016-06-07T14:22:56.982Z","_version":1,"_operation":"CREATE","_source":{ <...> }
    {"_index":"kforce_vac","_type":"searchdocument","_id":"T1BF0G91EHZR","_timestamp":"2016-06-07T14:22:55.762Z","_version":1,"_operation":"DELETE"}

where `_source` is the indexed document itself. Note that in case of DELETE, there is no `_source` field.

`in_emwebsocket.rb` listens local websocket on `:url` to get those messages, transforms them to JSON format and tags with appropriate tag name ("tag" config parameter).

`filter_json_merge.rb` transforms message by extracting the value of `_source` key (indexed document) to the root level. Example:

    before:
    {"_index":"sni_cv","_type":"searchdocument","_id":"CRJQ0FF67K490C2PP24Z","_timestamp":"2016-06-07T14:22:55.048Z","_version":2,"_operation":"INDEX","_source":{"extract me":"to the root"}}
    after:
    {"_index":"sni_cv","_type":"searchdocument","_id":"CRJQ0FF67K490C2PP24Z","_timestamp":"2016-06-07T14:22:55.048Z","_version":2,"_operation":"INDEX","extract me":"to the root"}

Optional, but suggested "remove" config parameter will remove `_source` key from the final message

Finally, `out_elasticsearch_patched.rb` sends everything to remote cluster, with custom behavior on `write_operation` parameter: it's actually ignored, and the lowercase value of `_operation` key is taken as bulk API action.

**Important**: `_operation` key is removed by `out_elasticsearch_patched.rb` plugin