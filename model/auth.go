package model

import (
	"context"
)

type AuthHandler struct {
	ClientSecret string
	ClientUUID   string
	ServerName   string
	ServerGroup  string
}

func (a *AuthHandler) GetRequestMetadata(ctx context.Context, uri ...string) (map[string]string, error) {
	metadata := map[string]string{
		"client_secret": a.ClientSecret,
		"client_uuid":   a.ClientUUID,
	}

	if a.ServerName != "" {
		metadata["server_name"] = a.ServerName
	}

	if a.ServerGroup != "" {
		metadata["server_group_name"] = a.ServerGroup
	}

	return metadata, nil
}

func (a *AuthHandler) RequireTransportSecurity() bool {
	return false
}
