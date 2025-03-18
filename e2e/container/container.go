package container_test

import (
	"time"

	"github.com/docker/go-connections/nat"
	"github.com/testcontainers/testcontainers-go"
	"github.com/testcontainers/testcontainers-go/wait"

	"context"
)

type Props struct {
	IP   string
	Port string
}

type ContainerTest struct {
	Container testcontainers.Container
	FilesPath []string
	Props     Props
}

type File struct {
	Path string
	File string
}

type ContainerInterface interface {
	GetProps() Props
}

var _ ContainerInterface = (*ContainerTest)(nil)

func New(ctx context.Context, context string, dockerfile string) (*ContainerTest, error) {
	req := testcontainers.ContainerRequest{
		FromDockerfile: testcontainers.FromDockerfile{
			Context:    context,
			Dockerfile: dockerfile,
		},
		ExposedPorts: []string{"8888/tcp"},
		WaitingFor:   wait.ForHTTP("/").WithStartupTimeout(10 * time.Second),
	}
	nginxContainer, err := testcontainers.GenericContainer(ctx, testcontainers.GenericContainerRequest{
		ContainerRequest: req,
		Started:          true,
	})
	if err != nil {
		return nil, err
	}
	ip, err := nginxContainer.Host(ctx)
	if err != nil {
		return nil, err
	}
	container := ContainerTest{}
	container.Props.IP = ip
	portString := "8888/tcp"
	natPort := nat.Port(portString)
	port, err := nginxContainer.MappedPort(ctx, natPort)
	if err != nil {
		return nil, err
	}
	container.Props.Port = port.Port()
	container.Container = nginxContainer
	return &container, nil
}

func (c *ContainerTest) GetProps() Props {
	return c.Props
}
