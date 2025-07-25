<clickhouse>
  <listen_host>0.0.0.0</listen_host>
  {{- if eq (index $ "TLS_ENABLED") "true" }}
  <https_port replace="replace" from_env="CLICKHOUSE_HTTPS_PORT"/>
  <tcp_port_secure replace="replace" from_env="CLICKHOUSE_TCP_SECURE_PORT"/>
  <interserver_https_port replace="replace" from_env="CLICKHOUSE_INTERSERVER_HTTPS_PORT"/>
  <http_port remove="remove"/>
  <tcp_port remove="remove"/>
  <interserver_http_port remove="remove"/>
  {{- else }}
  <http_port replace="replace" from_env="CLICKHOUSE_HTTP_PORT"/>
  <tcp_port replace="replace" from_env="CLICKHOUSE_TCP_PORT"/>
  <interserver_http_port replace="replace" from_env="CLICKHOUSE_INTERSERVER_HTTP_PORT"/>
  {{- end }}
  <logger>
      <level>information</level>
      <log>/bitnami/clickhouse/log/keeper-server.log</log>
      <errorlog>/bitnami/clickhouse/log/keeper-server.err.log</errorlog>
      <size>100M</size>
      <count>3</count>
  </logger>
  <keeper_server>
      {{- if eq (index $ "TLS_ENABLED") "true" }}
      <tcp_port_secure replace="replace" from_env="CLICKHOUSE_KEEPER_TCP_TLS_PORT"/>
      <secure>1</secure>
      {{- else }}
      <tcp_port replace="replace" from_env="CLICKHOUSE_KEEPER_TCP_PORT"/>
      {{- end }}
      <server_id from_env="CH_KEEPER_ID"/>
      <log_storage_path>/bitnami/clickhouse/coordination/log</log_storage_path>
      <snapshot_storage_path>/bitnami/clickhouse/coordination/snapshots</snapshot_storage_path>
      <enable_reconfiguration>true</enable_reconfiguration>
      <coordination_settings>
          <operation_timeout_ms>10000</operation_timeout_ms>
          <session_timeout_ms>30000</session_timeout_ms>
          <raft_logs_level>warning</raft_logs_level>
      </coordination_settings>
      <raft_configuration>
      {{- if eq (index $ "TLS_ENABLED") "true" }}
      <secure>true</secure>
      {{- end }}
      {{- range $id, $host := splitList "," .CH_KEEPER_POD_FQDN_LIST }}
        <server>
          <id>{{ add $id 1 }}</id>
          <hostname>{{ $host }}</hostname>
          {{- if eq (index $ "TLS_ENABLED") "true" }}
          <port replace="replace" from_env="CLICKHOUSE_KEEPER_RAFT_TLS_PORT"/>
          {{- else }}
          <port replace="replace" from_env="CLICKHOUSE_KEEPER_RAFT_PORT"/>
          {{- end }}
        </server>
        {{- end }}
      </raft_configuration>
  </keeper_server>
  <!-- Prometheus metrics -->
  <prometheus>
    <endpoint>/metrics</endpoint>
    <port replace="replace" from_env="CLICKHOUSE_METRICS_PORT"/>
    <metrics>true</metrics>
    <events>true</events>
    <asynchronous_metrics>true</asynchronous_metrics>
  </prometheus>
  <!-- tls configuration -->
  {{- if eq (index $ "TLS_ENABLED") "true" -}}
  {{- $CA_FILE := "/etc/pki/tls/ca.pem" -}}
  {{- $CERT_FILE := "/etc/pki/tls/cert.pem" -}}
  {{- $KEY_FILE := "/etc/pki/tls/key.pem" -}}
  <protocols>
    <prometheus_protocol>
      <type>prometheus</type>
      <description>prometheus protocol</description>
    </prometheus_protocol>
    <prometheus_secure>
      <type>tls</type>
      <impl>prometheus_protocol</impl>
      <description>prometheus over https</description>
      <certificateFile>{{$CERT_FILE}}</certificateFile>
      <privateKeyFile>{{$KEY_FILE}}</privateKeyFile>
    </prometheus_secure>
  </protocols>
  <openSSL>
    <server>
      <certificateFile>{{$CERT_FILE}}</certificateFile>
      <privateKeyFile>{{$KEY_FILE}}</privateKeyFile>
      <verificationMode>relaxed</verificationMode>
      <caConfig>{{$CA_FILE}}</caConfig>
      <cacheSessions>true</cacheSessions>
      <disableProtocols>sslv2,sslv3</disableProtocols>
      <preferServerCiphers>true</preferServerCiphers>
    </server>
    <client>
      <loadDefaultCAFile>false</loadDefaultCAFile>
      <certificateFile>{{$CERT_FILE}}</certificateFile>
      <privateKeyFile>{{$KEY_FILE}}</privateKeyFile>
      <caConfig>{{$CA_FILE}}</caConfig>
      <cacheSessions>true</cacheSessions>
      <disableProtocols>sslv2,sslv3</disableProtocols>
      <preferServerCiphers>true</preferServerCiphers>
      <verificationMode>relaxed</verificationMode>
      <invalidCertificateHandler>
        <name>RejectCertificateHandler</name>
      </invalidCertificateHandler>
    </client>
  </openSSL>
  <grpc>
    <enable_ssl>1</enable_ssl>
    <ssl_cert_file>{{$CERT_FILE}}</ssl_cert_file>
    <ssl_key_file>{{$KEY_FILE}}</ssl_key_file>
    <ssl_require_client_auth>true</ssl_require_client_auth>
    <ssl_ca_cert_file>{{$CA_FILE}}</ssl_ca_cert_file>
    <transport_compression_type>none</transport_compression_type>
    <transport_compression_level>0</transport_compression_level>
    <max_send_message_size>-1</max_send_message_size>
    <max_receive_message_size>-1</max_receive_message_size>
    <verbose_logs>false</verbose_logs>
  </grpc>
  {{- end }}
</clickhouse>
