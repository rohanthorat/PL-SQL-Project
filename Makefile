all:MenuDriven

MenuDriven:MenuDriven.java
	javac -cp "ojdbc6.jar" *.java

clean:
	rm -rf *.class