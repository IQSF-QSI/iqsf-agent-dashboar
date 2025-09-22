import React, { useEffect, useState } from 'react';
import supabase from '../supabaseClient';
import BrandLogo from '../components/BrandLogo';

export default function Dashboard() {
  const [log, setLog] = useState([]);
  useEffect(() => {
    supabase.from('activity_log').select('*').order('timestamp', { ascending: false })
      .then(({ data }) => setLog(data || []));
  }, []);
  return (
    <div className="dashboard">
      <BrandLogo />
      <h1>IQSF Agents: Activity Log</h1>
      <ul>
        {log.map(entry => (
          <li key={entry.id}>
            <span className={`badge badge-${entry.log_level}`}>{entry.log_level}</span>
            <b>{entry.agent_name}</b>: {entry.message} <i>{entry.timestamp}</i>
          </li>
        ))}
      </ul>
    </div>
  );
}
