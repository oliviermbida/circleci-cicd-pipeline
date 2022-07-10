#!/bin/bash

# Author: Olivier Mbida (olivier.mbida@ai-uavsystems.com)
# Usage: 
#   export TYPEORM_MIGRATIONS_DIR=directory_of_migrations
#   ./parse_report.sh migrations_report_file

if [ -z "${TYPEORM_MIGRATIONS_DIR:-}" ]; then
echo "In order to use this script a TYPEORM_MIGRATIONS_DIR environment variable must be present."
exit 1
fi
MIGRATIONS_REPORT=$1
MIGRATIONS_TESTS=$(ls $TYPEORM_MIGRATIONS_DIR | sed -e s/-/''/ -e s/.ts/''/ -e 's/\([0-9]*\) *\(.*\)/\2\1/' -e 's/^/Migration /g' -e 's/$/ has been executed successfully./g')
NUMBER_OF_TESTS=$(grep -c ^ $MIGRATIONS_TESTS)
GREEN='\033[0;32m'       
RED='\033[0;31m'        
NC='\033[0m' 

test_migrations () {
PARSE_RESULT=$(grep -Fx "$1" $2 >/dev/null; echo $?)
echo $PARSE_RESULT

case $PARSE_RESULT in
0)
  printf "TEST: ${GREEN}PASSED${NC}\n"
  ;;
*)
  printf "TEST: ${RED}FAILED${NC}\n"
  # trigger revert migrations
  #exit 1
  ;;           
esac
}

n=$(seq $NUMBER_OF_TESTS)
for i in $n
do

# define expected expression in migrations report
# e.g "Migration AddOrders1549375960026 has been executed successfully"
TEST_PASSED=$(sed -n "$i"p $MIGRATIONS_TESTS)
echo $TEST_PASSED
# parse migration report and assert expected expression
test_migrations "$TEST_PASSED" $MIGRATIONS_REPORT
done
          

