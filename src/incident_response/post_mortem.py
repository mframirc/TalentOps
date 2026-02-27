from datetime import datetime


def create_post_mortem_template(incident_data):
    """Crear template de post-mortem basado en incidente"""

    template = f"""
# Post-Mortem: {incident_data['title']}

## Executive Summary
{incident_data.get('summary', 'Incident description')}

## Timeline
- **Detection**: {incident_data.get('detection_time', 'Unknown')}
- **Start**: {incident_data.get('start_time', 'Unknown')}
- **Resolution**: {incident_data.get('end_time', 'Unknown')}
- **Duration**: {incident_data.get('duration', 'Unknown')}

## Impact
- **Users Affected**: {incident_data.get('users_affected', 0)}
- **Business Impact**: {incident_data.get('business_impact', 'Unknown')}
- **Data Loss**: {incident_data.get('data_loss', 'None')}

## Root Cause Analysis
{incident_data.get('root_cause', 'To be determined')}

## Resolution Steps
{chr(10).join(f"- {step}" for step in incident_data.get('resolution_steps', []))}

## Lessons Learned
### What went well
{chr(10).join(f"- {item}" for item in incident_data.get('went_well', []))}

### What could be improved
{chr(10).join(f"- {item}" for item in incident_data.get('improvements', []))}

## Action Items
{chr(10).join(f"- [ ] {item}" for item in incident_data.get('action_items', []))}

## Prevention Measures
{chr(10).join(f"- [ ] {item}" for item in incident_data.get('prevention', []))}

---
*Post-mortem completed on {datetime.now().strftime('%Y-%m-%d')}*
"""
    return template