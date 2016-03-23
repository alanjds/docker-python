# Inherit from Heroku's stack
FROM heroku/cedar:14

# Install scipy lib dependencies
RUN apt-get update && apt-get install -y \
    g++ \
    uuid \
    uuid-dev \
    libffi-dev \
    libblas-dev \
    liblapack-dev \
    libatlas-base-dev \
    libjpeg-dev \
    gfortran

# Save scipy lib dependencies
RUN mkdir -p /app/.heroku/vendor/lib
RUN cp -ra -t /app/.heroku/vendor/lib/ /usr/lib/libblas
RUN cp -ra -t /app/.heroku/vendor/lib/ /usr/lib/lapack
RUN dpkg -L libatlas-base-dev | grep '/usr/lib/'| grep -v '/usr/lib/atlas-base/' | xargs cp -ra -t /app/.heroku/vendor/lib/

# Save some disk space
RUN apt-get clean
RUN apt-get autoclean

# Internally, we arbitrarily use port 3000
ENV PORT 3000
# Which version of Python?
ENV PYTHON_VERSION python-2.7.10

# Add Python binaries to path.
ENV PATH /app/.heroku/python/bin/:$PATH

# Create some needed directories
RUN mkdir -p /app/.heroku/python /app/.profile.d
WORKDIR /app/user

# `init` is kept out of /app so it won't be duplicated on Heroku
# Heroku already has a mechanism for running .profile.d scripts,
# so this is just for local parity
COPY ./init /usr/bin/init

# Install Python
RUN curl -s https://lang-python.s3.amazonaws.com/cedar-14/runtimes/$PYTHON_VERSION.tar.gz | tar zx -C /app/.heroku/python

# Install Pip & Setuptools
RUN curl -s https://bootstrap.pypa.io/get-pip.py | /app/.heroku/python/bin/python

# Export the Python environment variables in .profile.d
RUN echo 'export PATH=$HOME/.heroku/python/bin:$PATH PYTHONUNBUFFERED=true PYTHONHOME=/app/.heroku/python LIBRARY_PATH=/app/.heroku/vendor/lib:/app/.heroku/python/lib:$LIBRARY_PATH LD_LIBRARY_PATH=/app/.heroku/vendor/lib:/app/.heroku/python/lib:$LD_LIBRARY_PATH LANG=${LANG:-en_US.UTF-8} PYTHONHASHSEED=${PYTHONHASHSEED:-random} PYTHONPATH=${PYTHONPATH:-/app/user/}' > /app/.profile.d/python.sh
RUN chmod +x /app/.profile.d/python.sh

# Preinstall scientific tools with lengthy compilation phase
RUN /app/.heroku/python/bin/pip install numpy
RUN /app/.heroku/python/bin/pip install scipy
RUN /app/.heroku/python/bin/pip install sklearn

ONBUILD ADD requirements.txt /app/user/
ONBUILD RUN /app/.heroku/python/bin/pip install -r requirements.txt
ONBUILD ADD . /app/user/

ENTRYPOINT ["/usr/bin/init"]
