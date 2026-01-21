FROM gcr.io/distroless/static-debian13:debug

ADD lxcfs-admission-webhook /lxcfs-admission-webhook
ENTRYPOINT ["./lxcfs-admission-webhook"]