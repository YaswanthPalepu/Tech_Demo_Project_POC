# src/framework_handlers/manager.py
"""
Framework manager to detect and manage framework handlers.
"""

from typing import Any, Dict, List, Optional

from .base_handler import BaseFrameworkHandler
from .django_handler import DjangoHandler
from .fastapi_handler import FastAPIHandler
from .flask_handler import FlaskHandler
from .universal_handler import UniversalHandler


class FrameworkManager:
    """Manages framework detection and handler selection (no scoring)."""
    
    def __init__(self):
        self.handlers = [
            DjangoHandler(),
            FastAPIHandler(),
            FlaskHandler(),
            UniversalHandler()  # Always last as fallback
        ]
        self.detected_framework: Optional[str] = None
        self.active_handler: Optional[BaseFrameworkHandler] = None

    # -----------------------------------------------------------------------
    def detect_framework(self, analysis: Dict[str, Any]) -> str:
        """
        Detect the main framework used in the project.
        Uses each handler's `can_handle()` to identify the framework realistically,
        without assigning numeric priorities or weights.
        The first positive match wins (ordered by detection confidence, not priority).
        """
        for handler in self.handlers:
            try:
                if handler.can_handle(analysis):
                    self.detected_framework = handler.framework_name
                    self.active_handler = handler
                    break
            except Exception as e:
                # Defensive logging: one handler failing should not block detection
                print(f"[framework_manager] Warning: {handler.framework_name} detection failed -> {e}")
                continue

        # Fallback to universal if nothing matched
        if not self.detected_framework:
            self.detected_framework = "universal"
            self.active_handler = self._get_handler("universal")

        print(f"[framework_manager] Detected framework: {self.detected_framework}")
        return self.detected_framework

    # -----------------------------------------------------------------------
    def get_active_handler(self) -> Optional[BaseFrameworkHandler]:
        """Return the currently active handler."""
        return self.active_handler

    def get_framework_dependencies(self) -> List[str]:
        """Get dependencies for the detected framework."""
        if self.active_handler:
            return self.active_handler.get_framework_dependencies()
        return []

    def setup_framework_environment(self, target_root):
        """Setup the environment for the detected framework (if needed)."""
        if self.active_handler:
            self.active_handler.setup_framework_environment(target_root)

    def get_framework_analysis(self, analysis: Dict[str, Any]) -> Dict[str, Any]:
        """Get framework-specific pattern analysis."""
        if self.active_handler:
            return self.active_handler.detect_framework_patterns(analysis)
        return {}

    def get_all_handlers(self) -> List[BaseFrameworkHandler]:
        """Return all available framework handlers."""
        return self.handlers

    # -----------------------------------------------------------------------
    def _get_handler(self, name: str) -> Optional[BaseFrameworkHandler]:
        """Find a handler by framework name."""
        for h in self.handlers:
            if h.framework_name == name:
                return h
        return None