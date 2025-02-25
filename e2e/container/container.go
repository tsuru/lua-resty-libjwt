package container_test

import (
	"fmt"
	"io"
	"os"
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
	AddFiles(file []File) error
	GetProps() Props
	Clear() error
	Terminate() error
	NginxToConfigDefault() error
	ChangeNginxConfigReadFile(nginxPath string) error
	ChangeNginxConfig(nginxConfig []byte) error
}

var _ ContainerInterface = (*ContainerTest)(nil)

func New(ctx context.Context, context string, dockerfile string) (*ContainerTest, error) {
	preferredPort := 8888
	finalPort := getAvailablePort(preferredPort)
	req := testcontainers.ContainerRequest{
		FromDockerfile: testcontainers.FromDockerfile{
			Context:    context,
			Dockerfile: dockerfile,
		},
		ExposedPorts: []string{fmt.Sprintf("%d/tcp", finalPort)},
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
	portString := fmt.Sprintf("%d/tcp", finalPort)
	natPort := nat.Port(portString)
	port, err := nginxContainer.MappedPort(ctx, natPort)
	if err != nil {
		return nil, err
	}
	container.Props.Port = port.Port()
	container.Container = nginxContainer
	if err := container.NginxToConfigDefault(); err != nil {
		return nil, err
	}
	return &container, nil
}

func (c *ContainerTest) AddFiles(files []File) error {
	for _, file := range files {
		c.FilesPath = append(c.FilesPath, file.Path)
		err := c.Container.CopyToContainer(context.Background(), []byte(file.File), file.Path, 0644)
		if err != nil {
			return err
		}
	}
	return nil
}

func (c *ContainerTest) Clear() error {
	for _, file := range c.FilesPath {
		_, _, err := c.Container.Exec(context.Background(), []string{"rm", file})
		if err != nil {
			return err
		}
	}
	return c.NginxToConfigDefault()
}

func (c *ContainerTest) NginxToConfigDefault() error {
	srcFile, err := os.Open("./container/nginx.conf")
	if err != nil {
		return fmt.Errorf("error opening nginx.conf: %w", err)
	}
	defer srcFile.Close()
	fileContent, err := io.ReadAll(srcFile)
	if err != nil {
		return fmt.Errorf("error reading nginx.conf: %w", err)
	}
	return c.ChangeNginxConfig(fileContent)
}

func (c *ContainerTest) ChangeNginxConfigReadFile(nginxPath string) error {
	nginxConf, err := os.ReadFile(nginxPath)
	if err != nil {
		return err
	}
	return c.ChangeNginxConfig(nginxConf)
}

func (c *ContainerTest) ChangeNginxConfig(nginxConfig []byte) error {
	_, _, err := c.Container.Exec(context.Background(), []string{"sh", "-c", "rm ", "/usr/local/openresty/nginx/conf/nginx.conf"})
	if err != nil {
		return err
	}
	err = c.Container.CopyToContainer(context.Background(), nginxConfig, "/usr/local/openresty/nginx/conf/nginx.conf", 0644)
	if err != nil {
		return err
	}
	_, _, err = c.Container.Exec(context.Background(), []string{"sh", "-c", "pkill -HUP openresty || openresty"})
	return err
}

func (c *ContainerTest) Terminate() error {
	return c.Container.Terminate(context.Background())
}

func (c *ContainerTest) GetProps() Props {
	return c.Props
}
