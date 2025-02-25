package jwks

import (
	"crypto/rand"
	"crypto/rsa"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"math/big"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

const rsaKeySize = 2048

type JWK struct {
	Kty string `json:"kty"`
	N   string `json:"n"`
	E   string `json:"e"`
	Kid string `json:"kid"`
	Alg string `json:"alg"`
	Use string `json:"use"`
}

type JWKS struct {
	Keys []JWK `json:"keys"`
}

func GenerateRSAKeys() (*rsa.PrivateKey, *rsa.PublicKey, error) {
	privateKey, err := rsa.GenerateKey(rand.Reader, rsaKeySize)
	if err != nil {
		return nil, nil, err
	}
	return privateKey, &privateKey.PublicKey, nil
}

type JWTParams struct {
	Name  string
	Email string
	KID   string
	Exp   int64
}

func CreateJWT(privateKey *rsa.PrivateKey, params JWTParams) (string, error) {
	claims := jwt.MapClaims{
		"sub":   "1234567890",
		"name":  "Tsuru",
		"admin": true,
		"iat":   time.Now().Unix(),
		"exp":   time.Now().Add(time.Hour * 24).Unix(),
	}
	token := jwt.NewWithClaims(jwt.SigningMethodRS256, claims)
	if params.Name != "" {
		claims["name"] = params.Name
	}
	if params.Email != "" {
		claims["email"] = params.Email
	}
	if params.KID != "" {
		token.Header["kid"] = params.KID
	}
	if params.Exp != 0 {
		claims["exp"] = params.Exp
	}
	return token.SignedString(privateKey)
}

func GenerateJWKS(publicKey *rsa.PublicKey, jwksParams JWKSParams) JWKS {
	nBytes := publicKey.N.Bytes()
	nBase64 := base64.RawURLEncoding.EncodeToString(nBytes)
	eBytes := big.NewInt(int64(publicKey.E)).Bytes()
	eBase64 := base64.RawURLEncoding.EncodeToString(eBytes)

	jwk := JWK{
		Kty: "RSA",
		N:   nBase64,
		E:   eBase64,
		Alg: "RS256",
		Use: "sig",
	}
	if jwksParams.KID != "" {
		jwk.Kid = jwksParams.KID
	}
	return JWKS{Keys: []JWK{jwk}}
}

type JWKSParams struct {
	KID string
}

func Generate(jwtParams JWTParams, jwksParams JWKSParams) (jwt string, jwks string, err error) {
	privateKey, publicKey, err := GenerateRSAKeys()
	if err != nil {
		return "", "", fmt.Errorf("error generating RSA keys: %v", err)
	}
	token, err := CreateJWT(privateKey, jwtParams)
	if err != nil {
		return "", "", fmt.Errorf("error creating JWT: %v", err)
	}
	jwksStruct := GenerateJWKS(publicKey, jwksParams)
	jwksJSON, err := json.MarshalIndent(jwksStruct, "", "  ")
	if err != nil {
		return "", "", fmt.Errorf("error generating JWKS: %v", err)
	}
	return token, string(jwksJSON), nil
}
