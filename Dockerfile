FROM mcr.microsoft.com/mssql/server:latest AS base
USER root

FROM base AS build
RUN apt-get update \
	&& apt-get install -y git build-essential \
	&& git clone https://github.com/batiati/dateoffset /dateoffset \
	&& cd /dateoffset \
    && make

FROM base AS final
USER root
COPY --from=build /dateoffset/dateoffset.so /usr/lib/dateoffset/dateoffset.so
COPY ./entrypoint.sh /entrypoint.sh
COPY ./initialize.sh /initialize.sh
COPY ./initialize.ps1 /initialize.ps1

RUN apt-get update \
		&& apt-get install -y \
			iproute2 \
			dnsutils \
			powershell \
		&& apt-get clean \
		&& chmod +x /entrypoint.sh \
		&& chmod +x /initialize.sh
	
# Environment variables
# ACCEPT_EULA = Must be Y (inherited from mssql image)
# SA_PASSWORD = Default sa password (inherited from mssql image)
# ENABLE_CLR = Y for enabling CLR
# ATTACH_PATH = Lookup path for any .json file with database to attach
# MAX_MEMORY = Defines the max SQL Server memory
# SA_NO_POLICY_PASSWORD = Overrides the default SA_PASSWORD without any policy (useful for tests)
# AUTO_CLOSE = Defines AUTO_CLOSE ON or OFF (Default OFF)
# RUN_AS_DATE = Defines a fake date to run, in format YYYY/MM/DD, or _ for real date

ENV ACCEPT_EULA="" \
    SA_PASSWORD="" \
    MAX_MEMORY="" \
	ENABLE_CLR="Y" \
    ATTACH_PATH="" \
    SA_NO_POLICY_PASSWORD="" \
    AUTO_CLOSE="OFF" \
    RUN_AS_DATE="_" \
    PATH="/opt/mssql-tools/bin:${PATH}"
	
# Since sqlsrv isn't the entrypoint anymore, needs tini to propagate term signals
# Please visit https://github.com/krallin/tini for more info
ADD https://github.com/krallin/tini/releases/download/v0.19.0/tini /tini
RUN chmod +x /tini
ENTRYPOINT ["/tini", "/entrypoint.sh"]