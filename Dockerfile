FROM mcr.microsoft.com/dotnet/aspnet:7.0 AS base
WORKDIR /app
EXPOSE 5224

ENV ASPNETCORE_URLS=http://+:5224

# Creates a non-root user with an explicit UID and adds permission to access the /app folder
# For more info, please refer to https://aka.ms/vscode-docker-dotnet-configure-containers
RUN adduser -u 5678 --disabled-password --gecos "" appuser && chown -R appuser /app
USER appuser

FROM --platform=$BUILDPLATFORM mcr.microsoft.com/dotnet/sdk:7.0.404-1-alpine3.18 AS build
ARG configuration=Release
WORKDIR /src
COPY ["FlashcardsApp.csproj", "./"]
RUN dotnet restore "FlashcardsApp.csproj"
COPY . .
WORKDIR "/src/."
RUN dotnet build "FlashcardsApp.csproj" -c $configuration -o /app/build
RUN apk update
RUN apk add --no-cache nodejs npm

FROM build AS publish
ARG configuration=Release
RUN dotnet publish "FlashcardsApp.csproj" -c $configuration -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "FlashcardsApp.dll"]
