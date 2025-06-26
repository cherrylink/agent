package model

import (
	"encoding/json"
	"testing"
)

func TestJsonUnmarshalConfig(t *testing.T) {
	var conf AgentConfig
	conf.Debug = true
	t.Logf("old conf: %+v", conf)
	var newConfJson = "{\"gpu\": true}"
	if err := json.Unmarshal([]byte(newConfJson), &conf); err != nil {
		t.Errorf("json unmarshal failed: %v", err)
	}
	t.Logf("new conf: %+v", conf)
	if conf.GPU != true {
		t.Errorf("json unmarshal failed: %v", conf.GPU)
	}
	if conf.Debug != true {
		t.Errorf("json unmarshal failed: %v", conf.Debug)
	}
}

func TestConfigValidation(t *testing.T) {
	tests := []struct {
		name   string
		config AgentConfig
		hasErr bool
	}{
		{
			name: "有效的配置",
			config: AgentConfig{
				Server:       "example.com:5555",
				ClientSecret: "secret",
				UUID:         "test-uuid",
			},
			hasErr: false,
		},
		{
			name: "缺少服务器地址",
			config: AgentConfig{
				ClientSecret: "secret",
				UUID:         "test-uuid",
			},
			hasErr: true,
		},
		{
			name: "缺少客户端密钥",
			config: AgentConfig{
				Server: "example.com:5555",
				UUID:   "test-uuid",
			},
			hasErr: true,
		},
		{
			name: "报告延迟超出范围",
			config: AgentConfig{
				Server:       "example.com:5555",
				ClientSecret: "secret",
				UUID:         "test-uuid",
				ReportDelay:  10, // 超出1-4的范围
			},
			hasErr: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := ValidateConfig(&tt.config, false)
			if (err != nil) != tt.hasErr {
				t.Errorf("ValidateConfig() error = %v, hasErr %v", err, tt.hasErr)
			}
		})
	}
}
