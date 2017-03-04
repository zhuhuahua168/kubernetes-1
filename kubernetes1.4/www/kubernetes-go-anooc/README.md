##如何使用这个镜像?

- 因所有镜像均位于境外服务器，为了确保所有示例能正常运行，DaoCloud 提供了一套境内镜像源，并与官方源保持同步。

###在你的应用中启动一个 Go 实例

>你可以使用本镜像来创建一个 Go 的容器作为应用的构建环境，也可作为运行环境。在你的Dockerfile中写下以下代码行，Docker 会编译并且运行你的项目：

    FROM golang:1.6-onbuild

上面指定的这个镜像包含'ONBUILD'触发器，这个构建会依次执行<code>COPY . /usr/src/app</code>，<code>RUN go get -d -v</code>，和<code>RUN go install -v</code>。

这个镜像也包含CMD ["app"]指令，表示应用的默认启动命令，不带任何参数。


接着，你可以构建并运行你的 Docker 镜像：

    docker build -t my-golang-app .
    docker run -it --rm --name my-running-app my-golang-app

###在 Docker 容器中编译你的应用

某些情况下，你并不需要在容器中运行你的应用，以下命令将使你在容器中编译，而不运行你的应用：

    docker run --rm -v "$PWD":/usr/src/myapp -w /usr/src/myapp golang:1.6 go build -v

这个命令将当前目录作为一个 volume 挂载进容器，并把这个 volume 设置成工作目录，然后运行命令go build来编译应用。如果你的工程包含一个Makefile，你也可以运行一下命令：

    docker run --rm -v "$PWD":/usr/src/myapp -w /usr/src/myapp golang:1.6 make

###在 Docker 容器中交叉编译

如果你的应用并非运行在 linux/amd64 上，比如 windows/386， 你同样可以利用 Docker 来编译：

    docker run --rm -v "$PWD":/usr/src/myapp -w /usr/src/myapp -e GOOS=windows -e GOARCH=386 daocloud.io/golang:1.3-cross go build -v

当然，你也可以使用以下脚本一次编译多个平台的版本：

    docker run --rm -it -v "$PWD":/usr/src/myapp -w /usr/src/myapp daocloud.io/golang:1.3-cross bash
    $ for GOOS in darwin linux; do
    >   for GOARCH in 386 amd64; do
    >     go build -v -o myapp-$GOOS-$GOARCH
    >   done
    > done
