const CHANNEL_CONFIG = {
  slack:       { label: 'Slack',        bg: 'bg-purple-100 text-purple-700' },
  teams:       { label: 'Teams',        bg: 'bg-blue-100 text-blue-700' },
  zoom:        { label: 'Zoom',         bg: 'bg-blue-100 text-blue-800' },
  google_meet: { label: 'Google Meet',  bg: 'bg-green-100 text-green-700' },
  email:       { label: 'Email',        bg: 'bg-gray-100 text-gray-700' },
  salesforce:  { label: 'Salesforce',   bg: 'bg-sky-100 text-sky-700' },
  hubspot:     { label: 'HubSpot',      bg: 'bg-orange-100 text-orange-700' },
}

export default function ChannelBadge({ channel }) {
  const cfg = CHANNEL_CONFIG[channel] || { label: channel, bg: 'bg-gray-100 text-gray-600' }
  return (
    <span className={`inline-flex items-center px-2 py-0.5 rounded text-xs font-medium ${cfg.bg}`}>
      {cfg.label}
    </span>
  )
}
