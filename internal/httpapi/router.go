package httpapi

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

type statusResponse struct {
	Status string `json:"status"`
}

func New() *gin.Engine {
	router := gin.New()
	router.Use(gin.Recovery())
	router.GET("/api/healthz", statusOK)
	router.GET("/api/readyz", statusOK)
	return router
}

func statusOK(c *gin.Context) {
	c.JSON(http.StatusOK, statusResponse{Status: "ok"})
}
