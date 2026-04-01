FOLDER=${1}

echo full analysis at ${FOLDER}

echo compile stats
python3 python/compile_set_stat_all.py ${FOLDER}

echo compile snapshots
python3 python/repo/compile_set_snapshots.py ${FOLDER}

echo ecompile stats individual
python3 python/compile_set_stat_indiv.py ${FOLDER}
