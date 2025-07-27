FROM golang:1.19 as builder
WORKDIR /workspace
COPY . .
RUN make build

FROM alpine:3.16
WORKDIR /
COPY --from=builder /workspace/bin/manager .
USER 65532:65532
ENTRYPOINT ["/manager"]