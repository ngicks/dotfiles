package proto

//go:generate protoc --go_out=.. --go_opt=module=github.com/watage/lsp-gw --go-grpc_out=.. --go-grpc_opt=module=github.com/watage/lsp-gw proto/lspgw.proto
