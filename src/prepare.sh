for f in *.coffee
do
		echo "processing $f..."
		coffee -o ../ -c $f
done
