package services

import (
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"somana-agent/internal/database"
	"somana-agent/internal/generated"
)

// HostService implements the generated ServerInterface for Host operations
type HostService struct{}

// NewHostService creates a new host service
func NewHostService() *HostService {
	return &HostService{}
}

// GetHealth implements the health check endpoint
func (s *HostService) GetHealth(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"status":  "ok",
		"message": "Somana API is running",
		"version": "1.0.0",
	})
}

// GetApiV1Hosts implements the list hosts endpoint
func (s *HostService) GetApiV1Hosts(c *gin.Context, params generated.GetApiV1HostsParams) {
	var hosts []generated.Host
	query := database.GetDB()

	// Apply status filter if provided
	if params.Status != nil {
		query = query.Where("status = ?", string(*params.Status))
	}

	result := query.Find(&hosts)
	if result.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": result.Error.Error()})
		return
	}

	c.JSON(http.StatusOK, hosts)
}

// PostApiV1Hosts implements the register host endpoint
func (s *HostService) PostApiV1Hosts(c *gin.Context) {
	var req generated.HostCreateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	host := &generated.Host{
		Hostname:  req.Hostname,
		IpAddress: req.IpAddress,
		OsName:    req.OsName,
		OsVersion: req.OsVersion,
		Status:    generated.HostStatusOnline, // Default status
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}

	result := database.GetDB().Create(host)
	if result.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": result.Error.Error()})
		return
	}

	c.JSON(http.StatusCreated, host)
}

// GetApiV1HostsId implements the get host by ID endpoint
func (s *HostService) GetApiV1HostsId(c *gin.Context, id int) {
	var host generated.Host
	result := database.GetDB().First(&host, id)
	if result.Error != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Host not found"})
		return
	}

	c.JSON(http.StatusOK, host)
}

// PutApiV1HostsId implements the update host endpoint
func (s *HostService) PutApiV1HostsId(c *gin.Context, id int) {
	var req generated.HostUpdateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var host generated.Host
	result := database.GetDB().First(&host, id)
	if result.Error != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Host not found"})
		return
	}

	// Update fields if provided
	if req.Hostname != nil {
		host.Hostname = *req.Hostname
	}
	if req.IpAddress != nil {
		host.IpAddress = *req.IpAddress
	}
	if req.Status != nil {
		host.Status = generated.HostStatus(*req.Status)
	}

	host.UpdatedAt = time.Now()

	result = database.GetDB().Save(&host)
	if result.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": result.Error.Error()})
		return
	}

	c.JSON(http.StatusOK, host)
}

// DeleteApiV1HostsId implements the deregister host endpoint
func (s *HostService) DeleteApiV1HostsId(c *gin.Context, id int) {
	var host generated.Host
	result := database.GetDB().First(&host, id)
	if result.Error != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Host not found"})
		return
	}

	result = database.GetDB().Delete(&host)
	if result.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": result.Error.Error()})
		return
	}

	c.Status(http.StatusNoContent)
}

// PostApiV1HostsIdHeartbeat implements the host heartbeat endpoint
func (s *HostService) PostApiV1HostsIdHeartbeat(c *gin.Context, id int) {
	var req generated.HostHeartbeatRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var host generated.Host
	result := database.GetDB().First(&host, id)
	if result.Error != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Host not found"})
		return
	}

	// Update status if provided
	if req.Status != nil {
		host.Status = generated.HostStatus(*req.Status)
	}

	host.UpdatedAt = time.Now()

	result = database.GetDB().Save(&host)
	if result.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": result.Error.Error()})
		return
	}

	c.JSON(http.StatusOK, host)
} 