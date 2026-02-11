package gateway

import (
	"reflect"
	"testing"
)

func TestNormalizeResult(t *testing.T) {
	tests := []struct {
		name string
		in   any
		want any
	}{
		{
			name: "nil",
			in:   nil,
			want: nil,
		},
		{
			name: "string",
			in:   "hello",
			want: "hello",
		},
		{
			name: "int",
			in:   42,
			want: 42,
		},
		{
			name: "bool",
			in:   true,
			want: true,
		},
		{
			name: "map[any]any to map[string]any",
			in:   map[any]any{"key": "value", 123: "num"},
			want: map[string]any{"key": "value", "123": "num"},
		},
		{
			name: "map[string]any preserved",
			in:   map[string]any{"a": 1, "b": "two"},
			want: map[string]any{"a": 1, "b": "two"},
		},
		{
			name: "slice with nested maps",
			in: []any{
				map[any]any{"k": "v"},
				"plain",
			},
			want: []any{
				map[string]any{"k": "v"},
				"plain",
			},
		},
		{
			name: "nested map[any]any",
			in: map[any]any{
				"outer": map[any]any{
					"inner": "deep",
				},
			},
			want: map[string]any{
				"outer": map[string]any{
					"inner": "deep",
				},
			},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := NormalizeResult(tt.in)
			if !reflect.DeepEqual(got, tt.want) {
				t.Errorf("NormalizeResult(%v) = %v, want %v", tt.in, got, tt.want)
			}
		})
	}
}
