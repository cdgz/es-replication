ES streaming replication
------------------------

This document explains how to setup uni-directional streaming replication between 2 Elasticsearch clusters

Requirements
------------

* Elasticsearch >= 1.4.0
* Elasticsearch changes feed plugin >= 1.4.0
* fluentd >= 0.12.20
* custom fluentd plugins (see src/)

Stream out
----------

Stream out changes from the cluster using websockets: install changes feed plugin and restart the cluster, node by node

	# installing v1.4.0
	/usr/share/elasticsearch/bin/plugin --install es-changes-feed-plugin --url  https://github.com/jurgc11/es-change-feed-plugin/releases/download/v1.4.0/es-changes-feed-plugin.zip

Listen and forward
------------------

Listen to websockets and forward changes to remote cluster: install 3 plugins fluentd plugins from src/ on every Elastic node, and launch fluentd daemon with below configuration file (replace `REMOTE_*` with your values):

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
	  type elasticsearch
	  host REMOTE_ELASTIC_NODE
	  port REMOTE_ELASTIC_PORT
	  target_index_key _index 
	  target_type_key _type
	  id_key _id
	  remove_keys _index, _type, _id, _timestamp, _version
	</match>