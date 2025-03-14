package e2e_test

import (
	"context"
	"fmt"
	"net/http"
	"testing"
	"time"

	assertTestify "github.com/stretchr/testify/assert"
	container_test "github.com/tsuru/lua-resty-libjwt/e2e/container"
	jwks_test "github.com/tsuru/lua-resty-libjwt/e2e/jwks"
	nginx_test "github.com/tsuru/lua-resty-libjwt/e2e/nginx"
	request_test "github.com/tsuru/lua-resty-libjwt/e2e/request"
)

func TestNginxContainer(t *testing.T) {
	assert := assertTestify.New(t)
	ctx := context.Background()
	var err error
	var containerTest container_test.ContainerInterface
	containerTest, err = container_test.New(ctx, "..", "Dockerfile.nginx")
	containerTestProps := containerTest.GetProps()
	assert.NoError(err)
	defer containerTest.Terminate()
	URL := fmt.Sprintf("http://%s:%s/private", containerTestProps.IP, containerTestProps.Port)

	t.Run("Should successfully return the nginx.default request", func(t *testing.T) {
		assert := assertTestify.New(t)
		containerTest.NginxToConfigDefault()
		containerTest.Clear()
		body, statusCode, err := request_test.Do(request_test.Params{URL: fmt.Sprintf("http://%s:%s", containerTestProps.IP, containerTestProps.Port)})
		assert.NoError(err)
		assert.Equal(http.StatusOK, statusCode)
		assert.Equal("{\"message\": \"content by nginx\"}", string(body))
	})
	t.Run("Should return an error when JWT is missing the kid", func(t *testing.T) {
		assert := assertTestify.New(t)
		containerTest.Clear()
		containerTest.ChangeNginxConfigReadFile("./nginx/nginx.private.jwks.conf")
		jwtWithoutKID, jwks, err := jwks_test.Generate(
			jwks_test.JWTParams{KID: ""}, jwks_test.JWKSParams{KID: "tsuru-kid-123"})
		assert.NoError(err)
		containerTest.AddFiles([]container_test.File{
			{Path: "/usr/share/tokens/jwks.json", File: jwks},
		})
		body, statusCode, err := request_test.Do(request_test.Params{
			URL:         URL,
			HeaderKey:   "Authorization",
			HeaderValue: fmt.Sprintf("Bearer %s", jwtWithoutKID),
		})
		assert.NoError(err)
		assert.Equal(http.StatusUnauthorized, statusCode)
		assert.Equal("{\"message\":\"kid not found\"}\n", string(body))
	})

	t.Run("Should return an error when JWT is generated by another key", func(t *testing.T) {
		assert := assertTestify.New(t)
		containerTest.Clear()
		containerTest.ChangeNginxConfigReadFile("./nginx/nginx.private.jwks.conf")
		_, jwks, err := jwks_test.Generate(
			jwks_test.JWTParams{}, jwks_test.JWKSParams{KID: "tsuru-kid-123"})
		assert.NoError(err)
		keyPrivate, _, _ := jwks_test.GenerateRSAKeys()
		jwtWithAnotherKey, err := jwks_test.CreateJWT(keyPrivate, jwks_test.JWTParams{
			KID: "tsuru-kid-123",
		})
		assert.NoError(err)
		containerTest.AddFiles([]container_test.File{
			{Path: "/usr/share/tokens/jwks.json", File: jwks},
		})
		body, statusCode, err := request_test.Do(request_test.Params{
			URL:         URL,
			HeaderKey:   "Authorization",
			HeaderValue: fmt.Sprintf("Bearer %s", jwtWithAnotherKey),
		})
		assert.NoError(err)
		assert.Equal(http.StatusUnauthorized, statusCode)
		assert.Equal("{\"message\":\"invalid token\"}\n", string(body))
	})
	t.Run("Should return an error when JWT header is not a token", func(t *testing.T) {
		assert := assertTestify.New(t)
		containerTest.Clear()
		containerTest.ChangeNginxConfigReadFile("./nginx/nginx.private.jwks.conf")
		_, jwks, err := jwks_test.Generate(
			jwks_test.JWTParams{}, jwks_test.JWKSParams{KID: "tsuru-kid-123"})
		assert.NoError(err)
		containerTest.AddFiles([]container_test.File{
			{Path: "/usr/share/tokens/jwks.json", File: jwks},
		})
		body, statusCode, err := request_test.Do(request_test.Params{
			URL:         URL,
			HeaderKey:   "Authorization",
			HeaderValue: "Bearer 123",
		})
		assert.NoError(err)
		assert.Equal(http.StatusUnauthorized, statusCode)
		assert.Equal("{\"message\":\"invalid JWT\"}\n", string(body))
	})
	t.Run("Should return an error when JWT header is missing a token", func(t *testing.T) {
		assert := assertTestify.New(t)
		containerTest.Clear()
		containerTest.ChangeNginxConfigReadFile("./nginx/nginx.private.jwks.conf")
		_, jwks, err := jwks_test.Generate(
			jwks_test.JWTParams{}, jwks_test.JWKSParams{KID: "tsuru-kid-123"})
		assert.NoError(err)
		containerTest.AddFiles([]container_test.File{
			{Path: "/usr/share/tokens/jwks.json", File: jwks},
		})
		body, statusCode, err := request_test.Do(request_test.Params{
			URL:         URL,
			HeaderKey:   "Authorization",
			HeaderValue: "Bearer",
		})
		assert.NoError(err)
		assert.Equal(http.StatusUnauthorized, statusCode)
		assert.Equal("{\"message\":\"token not found\"}\n", string(body))
	})
	t.Run("Should return an error when kid in JWT is different from JWKS", func(t *testing.T) {
		assert := assertTestify.New(t)
		containerTest.Clear()
		containerTest.ChangeNginxConfigReadFile("./nginx/nginx.private.jwks.conf")
		jwt, jwks, err := jwks_test.Generate(
			jwks_test.JWTParams{KID: "tsuru-kid-456"}, jwks_test.JWKSParams{KID: "tsuru-kid-123"})
		assert.NoError(err)
		containerTest.AddFiles([]container_test.File{
			{Path: "/usr/share/tokens/jwks.json", File: jwks},
		})
		body, statusCode, err := request_test.Do(request_test.Params{
			URL:         URL,
			HeaderKey:   "Authorization",
			HeaderValue: fmt.Sprintf("Bearer %s", jwt),
		})
		assert.NoError(err)
		assert.Equal(http.StatusUnauthorized, statusCode)
		assert.Equal("{\"message\":\"invalid token\"}\n", string(body))
	})
	t.Run("Should return an error when token in header is different from the parameter", func(t *testing.T) {
		assert := assertTestify.New(t)
		containerTest.Clear()
		containerTest.ChangeNginxConfigReadFile("./nginx/nginx.private.jwks.conf")
		jwt, jwks, err := jwks_test.Generate(
			jwks_test.JWTParams{KID: "tsuru-kid-123"}, jwks_test.JWKSParams{KID: "tsuru-kid-123"})
		assert.NoError(err)
		containerTest.AddFiles([]container_test.File{
			{Path: "/usr/share/tokens/jwks.json", File: jwks},
		})
		body, statusCode, err := request_test.Do(request_test.Params{
			URL:         URL,
			HeaderKey:   "Token",
			HeaderValue: fmt.Sprintf("Bearer %s", jwt),
		})
		assert.NoError(err)
		assert.Equal(http.StatusUnauthorized, statusCode)
		assert.Equal("{\"message\":\"token not found\"}\n", string(body))
	})

	t.Run("Should return an error when JWT is expired", func(t *testing.T) {
		assert := assertTestify.New(t)
		containerTest.Clear()
		containerTest.ChangeNginxConfigReadFile("./nginx/nginx.private.jwks.conf")
		date := time.Now()
		jwt, jwks, _ := jwks_test.Generate(
			jwks_test.JWTParams{KID: "tsuru-kid-123", Iat: date.Add(-2 * time.Hour).Unix(), Exp: date.Add(-1 * time.Hour).Unix()},
			jwks_test.JWKSParams{KID: "tsuru-kid-123"})
		containerTest.AddFiles([]container_test.File{
			{Path: "/usr/share/tokens/jwks.json", File: jwks},
		})
		body, statusCode, err := request_test.Do(request_test.Params{
			URL:         URL,
			HeaderKey:   "Authorization",
			HeaderValue: fmt.Sprintf("Bearer %s", jwt),
		})
		assert.NoError(err)
		assert.Equal(http.StatusUnauthorized, statusCode)
		assert.Equal("{\"message\":\"invalid token\"}\n", string(body))
	})

	t.Run("Should return success when a valid JWKS is provided", func(t *testing.T) {
		assert := assertTestify.New(t)
		containerTest.Clear()
		nginxConfBytes, err := nginx_test.ReplaceNginxConfig("./nginx/nginx.private.jwks.conf",
			[]string{"\"/usr/share/tokens/jwks_1.json\"", "\"/usr/share/tokens/jwks_2.json\""})
		assert.NoError(err)
		containerTest.ChangeNginxConfig(nginxConfBytes)
		_, jwksOne, _ := jwks_test.Generate(
			jwks_test.JWTParams{KID: "tsuru-kid-123"},
			jwks_test.JWKSParams{KID: "tsuru-kid-123"})
		containerTest.AddFiles([]container_test.File{
			{Path: "/usr/share/tokens/jwks_1.json", File: jwksOne},
		})
		jwtRequest, jwksRequest, _ := jwks_test.Generate(
			jwks_test.JWTParams{KID: "kid-123"},
			jwks_test.JWKSParams{KID: "kid-123"})
		body, statusCode, err := request_test.Do(request_test.Params{
			URL:         URL,
			HeaderKey:   "Authorization",
			HeaderValue: fmt.Sprintf("Bearer %s", jwtRequest),
		})
		assert.NoError(err)
		assert.Equal(http.StatusUnauthorized, statusCode)
		assert.Equal("{\"message\":\"invalid token\"}\n", string(body))
		containerTest.AddFiles([]container_test.File{
			{Path: "/usr/share/tokens/jwks_2.json", File: jwksRequest},
		})
		_, statusCode, err = request_test.Do(request_test.Params{
			URL:         URL,
			HeaderKey:   "Authorization",
			HeaderValue: fmt.Sprintf("Bearer %s", jwtRequest),
		})
		assert.NoError(err)
		assert.Equal(http.StatusOK, statusCode)
	})

}
