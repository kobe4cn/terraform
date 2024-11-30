package main

import (
	http "net/http"
	echo "github.com/labstack/echo/v4"
)

func main() {
	e := echo.New()
	e.GET("/hello", func(c echo.Context) error {
		return c.String(http.StatusOK, "Hello, World!")
	})
	e.Logger.Fatal(e.Start(":1323"))
}