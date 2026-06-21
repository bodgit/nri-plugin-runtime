package main

import (
	"context"
	"flag"
	"fmt"
	"os"

	"github.com/bodgit/nri-plugin-runtime/pkg/runtime"
	"github.com/containerd/nri/pkg/api"
	"github.com/containerd/nri/pkg/stub"
	"github.com/sirupsen/logrus"
	"sigs.k8s.io/yaml"
)

type config struct {
	ContainerIDEnv             string `json:"containerIDEnv"` //nolint:tagliatelle
	ContainerRuntimeNameEnv    string `json:"containerRuntimeNameEnv"`
	ContainerRuntimeVersionEnv string `json:"containerRuntimeVersionEnv"`
}

type plugin struct {
	stub    stub.Stub
	cfg     config
	logger  *logrus.Logger
	runtime string
	version string
}

func (p *plugin) Configure(_ context.Context, config, runtime, version string) (api.EventMask, error) {
	p.logger.Infof("Connected to %s/%s...", runtime, version)

	p.runtime, p.version = runtime, version

	if config == "" {
		return 0, nil
	}

	if err := yaml.Unmarshal([]byte(config), &p.cfg); err != nil {
		return 0, fmt.Errorf("failed to parse provided configuration: %w", err)
	}

	p.logger.Infof("Got configuration data %+v...", p.cfg)

	return 0, nil
}

//nolint:lll
func (p *plugin) CreateContainer(_ context.Context, _ *api.PodSandbox, ctr *api.Container) (*api.ContainerAdjustment, []*api.ContainerUpdate, error) {
	p.logger.Infof("Create container %s, id %s", ctr.GetName(), ctr.GetId())

	adjust := new(api.ContainerAdjustment)
	adjust.AddEnv(p.cfg.ContainerIDEnv, ctr.GetId())
	adjust.AddEnv(p.cfg.ContainerRuntimeNameEnv, p.runtime)
	adjust.AddEnv(p.cfg.ContainerRuntimeVersionEnv, p.version)

	return adjust, nil, nil
}

func (p *plugin) Shutdown(_ context.Context) {
	p.logger.Info("Shutting down")
}

func (p *plugin) onClose() {
	p.logger.Info("Connection to the runtime lost, exiting...")
	os.Exit(0)
}

var (
	_ stub.ConfigureInterface       = new(plugin)
	_ stub.CreateContainerInterface = new(plugin)
	_ stub.ShutdownInterface        = new(plugin)
)

func main() {
	var (
		pluginName string
		pluginIdx  string
		err        error
	)

	p := &plugin{
		logger: logrus.StandardLogger(),
	}

	p.logger.SetFormatter(&logrus.TextFormatter{
		PadLevelText: true,
	})

	flag.StringVar(&pluginName, "name", "", "plugin name to register to NRI")
	flag.StringVar(&pluginIdx, "idx", "", "plugin index to register to NRI")
	flag.StringVar(&p.cfg.ContainerIDEnv, "container-id-env", runtime.ContainerIDEnv, "environment variable to export the container ID")                                                   //nolint:lll
	flag.StringVar(&p.cfg.ContainerRuntimeNameEnv, "container-runtime-name-env", runtime.ContainerRuntimeNameEnv, "environment variable to export the container runtime name")             //nolint:lll
	flag.StringVar(&p.cfg.ContainerRuntimeVersionEnv, "container-runtime-version-env", runtime.ContainerRuntimeVersionEnv, "environment variable to export the container runtime version") //nolint:lll
	flag.Parse()

	opts := []stub.Option{
		stub.WithOnClose(p.onClose),
	}

	if pluginName != "" {
		opts = append(opts, stub.WithPluginName(pluginName))
	}

	if pluginIdx != "" {
		opts = append(opts, stub.WithPluginIdx(pluginIdx))
	}

	if p.stub, err = stub.New(p, opts...); err != nil {
		p.logger.Fatalf("failed to create plugin stub: %v", err)
	}

	if err = p.stub.Run(context.Background()); err != nil {
		p.logger.Errorf("plugin exited with error %v", err)
		os.Exit(1)
	}
}
