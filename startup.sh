#!/bin/bash

set -e

service postgresql start
exec odoo
exit 1
