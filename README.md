# Elasticsearch streaming replication

This document explains how to setup uni-directional streaming replication between 2 Elasticsearch clusters

### Requirements

* Elasticsearch >= 1.4.0
* [Elasticsearch changes feed plugin](https://github.com/jurgc11/es-change-feed-plugin) >= 1.4.0
* fluentd >= 0.12.20
* custom fluentd plugins (see `src/`)

### Stream out

Stream out changes from the cluster using websockets: install changes feed plugin and restart the cluster, node by node

	# installing v1.4.0
	/usr/share/elasticsearch/bin/plugin --install es-changes-feed-plugin --url  https://github.com/jurgc11/es-change-feed-plugin/releases/download/v1.4.0/es-changes-feed-plugin.zip

### Listen and forward

Listen to websockets and forward changes to remote cluster:

* install fluentd daemon and 3 plugins plugins from `src/` on every Elastic node (check `src/README.md` for dependencies)
* launch fluentd daemon with below configuration file (replace `REMOTE_*` with your values)


	<source>
	  type emwebsocket
	  url ws://localhost:9400/ws/_changes
	  tag streaming
	</source>

	<filter streaming>
	  type json_merge
	  key _source
	  remove true
	</filter>

	<match streaming> 
	  type elasticsearch-patched
	  host REMOTE_ELASTIC_NODE
	  port REMOTE_ELASTIC_PORT
	  target_index_key _index 
	  target_type_key _type
	  id_key _id
	  remove_keys _index, _type, _id, _timestamp, _version
	</match>

### Troubleshooting

If everything goes right, in the logs of every fluentd daemon you should see:

    2016-07-25 16:29:35 +0200 [info]: Connected to ws://localhost:9400/ws/_changes
    2016-07-25 16:30:36 +0200 [info]: Connection opened to Elasticsearch cluster => {:host=>"REMOTE_ELASTIC_NODE", :port=>REMOTE_ELASTIC_PORT, :scheme=>"http"}

If you don't see those messages, and nothing on remote cluster - try to debug by running fluentd in attached mode (`-c conf -p plugins`)

### Background

This solution runs in production on relatively high load ES setup (>100k creates/updates/deletes per day). It was tested during DC-failover simulation, when entry point was switched from colocated hardware to AWS, where all data is live-replicated (1T+ of Postgres / Cassandra / Elasticsearch) 

Initially, logstash was used as shipping daemon. Due to its instability on big amounts of data, we decided to switch to fluentd. Nevertheless, big thanks to logstash community for reactive support

### Acknowledgements

@jurgc11, @uken, ES community for clear directions, logstash community for trying to help
