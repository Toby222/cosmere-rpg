set -e
set -x

script_dir=$(dirname $(readlink -f $0))
project_dir=$(dirname $script_dir)
pushd $project_dir

project_name="${project_dir##*/}"
target_dir=/var/lib/foundryvtt/Data/systems/$project_name

if [ "$target_dir" = "$project_dir" ]; then
  echo "Target directory is the same as the project directory. Cloned in RimWorld/projects. Skipping setup"
else
  sudo mkdir -p $target_dir
  sudo chown foundryvtt:foundryvtt $target_dir
  sudo rsync -av --delete $project_dir/build/* $target_dir/ --chown foundryvtt:foundryvtt
fi

popd
