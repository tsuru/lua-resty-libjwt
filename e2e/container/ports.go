package container_test

import (
	"net"
	"strconv"
)

func getAvailablePort(preferred int) int {
	if isPortAvailable(preferred) {
		return preferred
	}
	listener, err := net.Listen("tcp", ":0")
	if err != nil {
		panic("Falha ao encontrar uma porta disponível")
	}
	defer listener.Close()

	addr := listener.Addr().(*net.TCPAddr)
	return addr.Port
}

func isPortAvailable(port int) bool {
	listener, err := net.Listen("tcp", ":"+strconv.Itoa(port))
	if err != nil {
		return false
	}
	_ = listener.Close()
	return true
}
