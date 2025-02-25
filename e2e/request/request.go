package request_test

import (
	"io"
	"net/http"
)

type Params struct {
	URL         string
	HeaderKey   string
	HeaderValue string
}

func Do(params Params) (body []byte, statusCode int, err error) {
	client := http.Client{}
	req, err := http.NewRequest(http.MethodGet, params.URL, nil)
	if err != nil {
		return nil, statusCode, err
	}
	if params.HeaderKey != "" && params.HeaderValue != "" {
		req.Header.Add(params.HeaderKey, params.HeaderValue)
	}
	resp, err := client.Do(req)
	if err != nil {
		return nil, statusCode, err
	}
	defer resp.Body.Close()
	statusCode = resp.StatusCode
	body, err = io.ReadAll(resp.Body)
	if err != nil {
		return nil, statusCode, err
	}
	return body, statusCode, nil
}
