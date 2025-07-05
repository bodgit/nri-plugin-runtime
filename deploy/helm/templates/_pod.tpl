{{- define "nri-plugin.pod" -}}
{{- $root := . -}}
{{- with .Values.schedulerName }}
schedulerName: "{{ . }}"
{{- end }}
serviceAccountName: {{ include "nri-plugin.serviceAccountName" . }}
{{- with .Values.podSecurityContext }}
securityContext:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- if .Values.nri.runtime.patchConfig }}
initContainers:
  - name: patch-runtime
    {{- if (not (or (eq .Values.nri.runtime.config nil) (eq .Values.nri.runtime.config.pluginRegistrationTimeout ""))) }}
    args:
      - -nri-plugin-registration-timeout
      - {{ .Values.nri.runtime.config.pluginRegistrationTimeout }}
      - -nri-plugin-request-timeout
      - {{ .Values.nri.runtime.config.pluginRequestTimeout }}
    {{- end }}
    {{- $registry := .Values.global.imageRegistry | default .Values.initContainerImage.registry -}}
    {{- if .Values.initContainerImage.sha }}
    image: "{{ $registry }}/{{ .Values.initContainerImage.repository }}:{{ .Values.initContainerImage.tag }}@sha256:{{ .Values.initContainerImage.sha }}"
    {{- else }}
    image: "{{ $registry }}/{{ .Values.initContainerImage.repository }}:{{ .Values.initContainerImage.tag }}"
    {{- end }}
    imagePullPolicy: {{ .Values.initContainerImage.pullPolicy }}
    securityContext:
      allowPrivilegeEscalation: false
      capabilities:
        drop:
          - ALL
      privileged: false
    {{- with .Values.resources }}
    resources:
      {{- toYaml . | nindent 6 }}
    {{- end }}
    volumeMounts:
      - name: containerd-config
        mountPath: /etc/containerd
      - name: crio-config
        mountPath: /etc/crio/crio.conf.d
      - name: dbus-socket
        mountPath: /var/run/dbus/system_bus_socket
{{- end }}
containers:
  - name: {{ .Chart.Name }}
    args:
      - -idx
      - {{ .Values.nri.plugin.index | int | printf "%02d" | quote }}
    {{- $registry := .Values.global.imageRegistry | default .Values.image.registry -}}
    {{- if .Values.image.sha }}
    image: "{{ $registry }}/{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}@sha256:{{ .Values.image.sha }}"
    {{- else }}
    image: "{{ $registry }}/{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
    {{- end }}
    imagePullPolicy: {{ .Values.image.pullPolicy }}
    securityContext:
      allowPrivilegeEscalation: false
      capabilities:
        drop:
          - ALL
      privileged: false
    {{- with .Values.resources }}
    resources:
      {{- toYaml . | nindent 6 }}
    {{- end }}
    volumeMounts:
      - name: nrisockets
        mountPath: /var/run/nri
{{- with .Values.podPriorityClassName }}
priorityClassName: "{{ . }}"
{{- end }}
volumes:
  - name: nrisockets
    hostPath:
      path: /var/run/nri
      type: DirectoryOrCreate
  {{- if .Values.nri.runtime.patchConfig }}
  - name: containerd-config
    hostPath:
      path: /etc/containerd
      type: DirectoryOrCreate
  - name: crio-config
    hostPath:
      path: /etc/crio/crio.conf.d
      type: DirectoryOrCreate
  - name: dbus-socket
    hostPath:
      path: /var/run/dbus/system_bus_socket
      type: Socket
  {{- end }}
{{- with .Values.tolerations }}
tolerations:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end }}
